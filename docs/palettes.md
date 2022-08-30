# Dynamic palette system

## Sprite palettes

Keep in mind: palettes 0-3 ignore color math effects,
though this isn't that big of an issue.

Palettes 0-3 are for enemies and other objects, and are allocated as needed.
Palettes 4 and 5 are reserved for either champion enemies or bosses.
Palettes 6 and 7 are reserved for the player and their tears (and possibly other things).

Colors 0-2 of every palette: transparent, black, and white.
Fourth color is typically some neutral color (typically gray)

Colors 4-15
