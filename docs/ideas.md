# Ideas

## Dynamic floors
Dynamically generate floor tiles with raster rendering.

Storing all of the tiles for this would require 12KB ($1800 VRAM words).

May be difficult to sync with game data. Also, if changing palettes b/t tiles,
will also need to change tiles while updating character data.

### Idea: Use BG3 for this.
Only 2bpp would only require 6KB character data ($0C00 VRAM words)

Lower resolution, though may need more trickery to get colors right

Can't use layer for FX as effectively (perhaps disable this layer for FX?)

### Uses
visualizing explosion, blood effects, etc.

Since a given effect probably only needs one of a few colors
(blood - reds, bomb - grays, etc. + regular bg color), using 2bbp is feasible

## Conjoined transformation

Getting 3+ shooting familiars either 'conjoins' them to the player, or conjoins
them all together.