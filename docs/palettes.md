# Dynamic palette system

## Sprite palettes

Keep in mind: palettes 0-3 ignore color math effects,
HOWEVER: palettes 4-7 obey color math effects.
Since we use sprites for shadows (which are transparent), this limits us to four opaque palettes.

For each palette:
Color 0: transparent
Color 1: black
Color 2: white
Color 3: neutral (grey-ish)
Colors 4-15 are split into four groups of three colors consisting of a base, a shade, and a highlight

Palette 0: base palette. Used by isaac and his tears. Always loaded.
    (flesh) (blood) (tear/water)

Palettes 1-3 are dynamically loaded.

Palettes 4-7 will be used for shadows/highlights as needed.
