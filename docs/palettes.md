# Dynamic palette system

re-written to match current palette allocation system.

## Tile palettes

Tile palettes are statically allocated, depending on the current room.

| Index | Usage |
| ----- | ----- |
|     0 | Ground palette; 4 palettes, 4 colors each. |
|     1 | Active item and trinket slot 1 (swapped during frame with HDMA). |
|     2 | Current room tileset #1 |
|     3 | Current room tileset #2 |
|     4 | Currently unused. May re-organize this to be active item/trinket slot palette instead, so that palette 1 can be used for the current room's tileset as well. |
|     5 | UI #1 and trinket slot 2 (swapped during frame with HDMA). |
|     6 | UI #2 |
|     7 | Consumable slot |

## Sprite palettes

Sprite palettes 0-3 appear opaque. Sprite palettes 4-7 appear translucent via color math.

Sprite palettes are dynamically allocated, except for three static palettes:

| Index | Usage |
| ----- | ----- |
|     0 | Default entity palette (common colors - skin, tears, blood, etc.) (opaque) |
|     4 | Default entity palette (translucent) |
|     7 | Enemy damaged palette (mostly solid red) (translucent) |

Palettes 1, 2, and 3 are dynamically allocated opaque palettes.
Palettes 5 and 6 are dynamically allocated translucent palettes.

Each dynamic palette is split into four sections, each with four colors, called 'subpalettes.'
The first subpalette (subpalette 0) is static, and always contains these four colors: transparent, black, white, and gray. The other three subpalettes are independently allocated upon request.

A palette allocation request specifies the a number of required colors, which determines how many subpalettes are needed. Zero subpalettes are allocated if four or fewer colors are requested (first four colors are assumed to be static); One subpalette is allocated if 5-8 colors are requested; Two subpalettes in the same palette are allocated if 9-12 colors are requested; and all three subpalettes in the same palette are allocated if 13-16 colors are requested.

While all allocated subpalettes for a request must be in the same palette, they do not need to be contiguous. i.e., if two subpalettes are allocated for a single request, it is possible that these may be the second and fourth subpalette.

### Sprite swizzling

Dynamic palette allocation allows for sprites which use relatively few colors to share the same palette. The caveat, however, is that the sprite must be processed before sending to the PPU. The color indices in the character data is swizzled.

In the following chart, 'palette allocation' refers to which subpalettes are allocated (subpalette 0 is ignored). The 'character swizzle mode' will be explained afterwards.

| Palette Allocation | Character swizzle mode |
| ----- | ----- |
|     1 | A, B |
|     2 | B, A\|B |
|     3 | A, A
|   1,2 | A, B |
|   2,3 | B, A\|B |
|   1,3 | A\|B, A | 
| 1,2,3 | A, B |

From this chart, there are four swizzle modes: `A,B`, `A,A`, `A|B,A`, and `B,A|B`.

The 'swizzle mode' refers to the logical operation which is performed on the top two bits of each 4-bit color. The bottom two bits are left alone. This is because there are four subpalettes (selected by the top two bits), each of which has four colors (selected by the bottom two bits).
So, if we have a pixel with the color determined by the bits `A,B,C,D`, and we apply swizzle mode `A|B,A`, then the color that is sent to the PPU will be `A|B,A,C,D`.

This also means that swizzle mode `A,B` does not change the character data at all, and this makes sense: If we allocate the subpalettes in order, then we just use the palette as-is (e.g., we allocate subpalettes 1 and 2; since these are the first two subpalettes, no change needs to be made to the character data for it to properly display).
