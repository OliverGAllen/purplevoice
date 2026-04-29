# PurpleVoice - Assets

`icon.svg` is the source-of-truth, hand-authored.
`icon-256.png` is the derived 256x256 raster used by setup.sh banner / README header / future macOS app bundle.

## Regenerate the PNG after editing icon.svg

```sh
/usr/bin/sips -s format png --resampleHeightWidth 256 256 assets/icon.svg --out assets/icon-256.png
```

`sips` is built into macOS - no external dependency.

## Brand colour

Lavender `#B388EB` - locked per BRD-03 / CONTEXT.md D-09. Used for the menubar glyph and the icon background.
