#!/usr/bin/env bash
# tests/security/verify_egress.sh — PurpleVoice Phase 2.7 security verification.
# Asserts: zero outbound network egress from purplevoice process tree during a
#          recording window (SEC-02). Uses 3-layer evidence chain (lsof + nettop
#          + pf+tcpdump) with positive-control pf-efficacy check per RESEARCH
#          Pitfall 1 (macOS Sequoia 15.7.5 pf regression).
# Source of claim: SECURITY.md §"Egress Verification".
# Sudo: optional (graceful skip; layers 1-2 still run; layer 3 skipped if no sudo).
set -uo pipefail
cd "$(dirname "$0")/../.."   # repo root
REPO_ROOT="$(pwd)"

source tests/security/lib/process_tree.sh

ANCHOR_NAME="purplevoice-egress"
PF_RULE_FILE="/tmp/purplevoice-egress.pf"
PCAP_PFLOG="/tmp/purplevoice-egress-pflog.pcap"
PCAP_ANY="/tmp/purplevoice-egress-any.pcap"
POSITIVE_CTRL_LOG="/tmp/purplevoice-pf-positive-control.log"
LAYER1_FAIL=0
LAYER2_FAIL=0
LAYER3_FAIL=0
LAYER3_SKIPPED=0
PF_BROKEN=0

# Trap cleanup — always tear down pf anchor + remove temp files.
cleanup() {
  if [ "${SUDO_AVAILABLE:-0}" = "1" ]; then
    sudo pfctl -a "$ANCHOR_NAME" -F all 2>/dev/null || true
  fi
  rm -f "$PF_RULE_FILE" "$PCAP_PFLOG" "$PCAP_ANY" "$POSITIVE_CTRL_LOG"
  # Kill any lingering background processes from this script
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# -------------------------------------------------------------------------
# Sudo handling (Pattern 10: graceful skip)
# -------------------------------------------------------------------------
if sudo -n true 2>/dev/null; then
  SUDO_AVAILABLE=1
else
  echo "  verify_egress.sh: sudo not available — layer 3 (pf+tcpdump) will be skipped." >&2
  echo "  Run interactively or pre-authenticate sudo for the strongest evidence layer." >&2
  echo "  Layers 1-2 (lsof + nettop) will still run; egress claim rests on socket-state evidence." >&2
  SUDO_AVAILABLE=0
fi

# -------------------------------------------------------------------------
# Layer 3 prep (if sudo): build pf anchor + start tcpdumps
# -------------------------------------------------------------------------
if [ "$SUDO_AVAILABLE" = "1" ]; then
  PURPLEVOICE_UID=$(id -u)
  cat > "$PF_RULE_FILE" <<EOF
# Block all outbound TCP/UDP for UID $PURPLEVOICE_UID, log on pflog0
block log out quick proto { tcp udp } from any to any user $PURPLEVOICE_UID
EOF
  sudo pfctl -a "$ANCHOR_NAME" -f "$PF_RULE_FILE" 2>/dev/null
  sudo pfctl -e 2>/dev/null || true   # enable pf if not already (no-op if enabled)

  # Pitfall 1 positive control: try a network call under the anchor BEFORE
  # the recording window. If pf is enforcing, this curl MUST fail.
  # If curl succeeds, pf is broken on this macOS build (Sequoia regression).
  if curl --max-time 2 --silent --output /dev/null --write-out '%{http_code}' \
       https://example.com > "$POSITIVE_CTRL_LOG" 2>&1; then
    # curl reached example.com — pf is NOT enforcing.
    PF_BROKEN=1
    echo "  WARN [Pitfall 1]: pf positive-control failed — pf rules are silently bypassed on this macOS build." >&2
    echo "  Layer 3 (pf+tcpdump) is unreliable; layers 1-2 (lsof+nettop) carry the egress claim." >&2
  fi

  # Start tcpdumps in background for the recording window
  sudo tcpdump -nn -i pflog0 -w "$PCAP_PFLOG" 2>/dev/null &
  PFLOG_PID=$!
  sudo tcpdump -nn -i any -w "$PCAP_ANY" \
    '(tcp or udp) and not (host 127.0.0.1 or host ::1)' 2>/dev/null &
  ANY_PID=$!
  sleep 0.5  # let tcpdump initialise
fi

# -------------------------------------------------------------------------
# Synthesise a recording (Pitfall 6: helper invokes purplevoice-record only,
# not the transcription binary directly — Pattern 2 boundary preserved)
# -------------------------------------------------------------------------
mkdir -p /tmp/purplevoice
RECORD_BG_PID=$(synthesise_recording 2.0)

# Take 3 snapshots during the recording window
SNAPSHOT_PIDS=""
for snap in 1 2 3; do
  sleep 0.3
  PIDS=$(purplevoice_pid_tree)
  if [ -n "$PIDS" ]; then
    SNAPSHOT_PIDS="$SNAPSHOT_PIDS $PIDS"
  fi

  # -------------------------------------------------------------------------
  # Layer 1: lsof socket snapshot (no sudo)
  # -------------------------------------------------------------------------
  # CRITICAL macOS-specific syntax: BSD lsof intersects filters with `-a` (AND).
  # `lsof -i -p PID` (without -a) returns the UNION (-i sockets system-wide PLUS
  # PID's open files of any type), not the per-PID socket list. `lsof -p PID -a -i`
  # correctly returns ONLY the network sockets owned by PID.
  for pid in $PIDS; do
    # When no sockets, lsof prints nothing (no header). When sockets exist,
    # lsof prints header + 1 line per socket. >0 lines = real sockets.
    socket_count=$(lsof -p "$pid" -a -i 2>/dev/null | wc -l | awk '{print $1}')
    if [ "$socket_count" -gt 0 ]; then
      echo "  FAIL Layer 1: PID $pid has $socket_count network sockets at snapshot $snap" >&2
      LAYER1_FAIL=1
    fi
  done

  # -------------------------------------------------------------------------
  # Layer 2: nettop flow snapshot (no sudo)
  # -------------------------------------------------------------------------
  for pid in $PIDS; do
    # nettop -L 1 prints column header + 1 sample; expect 1 row (header) if no flows.
    flow_count=$(nettop -x -P -p "$pid" -L 1 2>/dev/null | wc -l | awk '{print $1}')
    if [ "$flow_count" -gt 2 ]; then
      # >2 because nettop -L 1 sometimes prints 2 header lines + sample row;
      # tolerate up to 2 header lines but flag any actual data rows.
      echo "  FAIL Layer 2: PID $pid has $flow_count nettop rows at snapshot $snap (expected <=2 headers)" >&2
      LAYER2_FAIL=1
    fi
  done
done

# Wait for the recording to complete
wait "$RECORD_BG_PID" 2>/dev/null || true

# -------------------------------------------------------------------------
# Layer 3 finalisation (if sudo): stop tcpdumps + parse captures
# -------------------------------------------------------------------------
if [ "$SUDO_AVAILABLE" = "1" ]; then
  sudo kill "$PFLOG_PID" "$ANY_PID" 2>/dev/null || true
  wait "$PFLOG_PID" "$ANY_PID" 2>/dev/null || true

  if [ "$PF_BROKEN" = "1" ]; then
    # pf is broken; cannot trust layer 3 evidence — skip the assertion.
    LAYER3_SKIPPED=1
  else
    # Parse pflog pcap: any packet logged here is one that pf BLOCKED — this
    # WOULD have been an egress attempt. Count >0 = layer 3 fail.
    if [ -s "$PCAP_PFLOG" ]; then
      # Use tcpdump to read the pcap and count packets
      PFLOG_PKTS=$(sudo tcpdump -r "$PCAP_PFLOG" 2>/dev/null | wc -l | awk '{print $1}')
      if [ "$PFLOG_PKTS" -gt 0 ]; then
        # Cross-reference: were any of these packets attributable to our PIDs?
        # Without per-PID packet attribution from tcpdump, we treat any pflog
        # output during the recording window as a fail signal.
        echo "  FAIL Layer 3: $PFLOG_PKTS packets blocked by pf during recording window" >&2
        LAYER3_FAIL=1
      fi
    fi

    # Parse any-interface pcap for non-loopback, non-multicast traffic that
    # could be attributable to the process tree. Without per-PID attribution,
    # this is best-effort — combined with layer 1+2 evidence.
    if [ -s "$PCAP_ANY" ]; then
      ANY_PKTS=$(sudo tcpdump -r "$PCAP_ANY" 2>/dev/null | grep -vE '(IGMP|MDNS|ARP)' | wc -l | awk '{print $1}')
      # We don't fail on any-interface packets alone (could be unrelated system
      # traffic from other PIDs); we just log the count for transparency.
      echo "  Layer 3 transparency: $ANY_PKTS non-multicast packets observed system-wide during recording window" >&2
    fi
  fi
else
  LAYER3_SKIPPED=1
fi

# -------------------------------------------------------------------------
# Decision logic
# -------------------------------------------------------------------------
if [ "$LAYER1_FAIL" = "1" ] || [ "$LAYER2_FAIL" = "1" ] || [ "$LAYER3_FAIL" = "1" ]; then
  echo "FAIL [verify_egress.sh]: egress detected — layer1=$LAYER1_FAIL layer2=$LAYER2_FAIL layer3=$LAYER3_FAIL" >&2
  exit 1
fi

if [ "$LAYER3_SKIPPED" = "1" ] && [ "$PF_BROKEN" = "1" ]; then
  echo "PASS (weakened — pf broken on this macOS build per Pitfall 1; layers 1-2 carry the claim)"
elif [ "$LAYER3_SKIPPED" = "1" ]; then
  echo "PASS (weakened — layer 3 pf+tcpdump skipped due to sudo unavailable; layers 1-2 carry the claim)"
else
  echo "PASS (full 3-layer evidence: lsof + nettop + pf+tcpdump silence on purplevoice process tree)"
fi
exit 0
