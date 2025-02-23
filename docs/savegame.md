## full, uncompressed save

  64B - map tile type
  64B - map tile flag
  12B - RNG state
   1B - used slots
 ~~160B - map tile -> room slot~~ - dont need; can just reverse room slot -> map tile
  64B - room slot -> map tile
  64B - room types
 128B - doors
   6B - room locations
   3B - pickups
  16B - health
 256B - items
  64B - room types
 128B - room RNG
6144B - tile types
6144B - tile variants
9216B - serialized entities
= 22,374B per saved game

If I map tile types and their variants into a single byte of valid values,
I could maybe save 6K without issue.
Cutting down on serialized entities might not be feasible; if we only store
existing entities, we might run the risk of running out of space in cases where
the player has somehow spawned 24 serializable entities in every room. Maybe
save 1.5K by combining X and Y coordinates? Could also just hard-cap number of
serialized entities in save slot.

Regardless, we'd be limited to just one save slot per cartridge.

## floor transition save

If we only save on floor transition:
  12B - RNG state
   3B - pickups
  16B - health
 256B - items
= 287B per saved game

## compression

Most rooms are either empty space, or comprised of many of the same block
type. A form of RLE would probably suffice, but doesn't capture the whole story.
Maybe something like (for each room):

tile_type_table_size db
tile_type_table: dw (tile_type_table_size)
tiles: ds

Tile format: %aabbccdd
Next four tiles are `tile_type_table[a]`, `tile_type_table[b]`,
`tile_type_table[c]`, `tile_type_table[d]`. UNLESS value is %11; then, we
insert a whole byte after this one.

Best case:
1B tile_type_table_size
2B-6B tile_type_table
24B tiles
= 31B (1984B for all rooms)

Worst case:
1B tile_type_table_size
192B tile_type_table
120B tiles
= 313B (20K, wouldn't even fit in 8K bank)
But: odds of every single tile being unique are unlikely

We reserve 1024B of each save bank for everything that isn't tiles and entities.
Rest of 8K bank after tiles is reserved for entities. We can't compress them, but we can hope
that there is enough space for all of them. And those that aren't lucky will just get deleted.
In our 'best case scenario', we have 5K reserved for entities. Maybe:
%TTTTTTTT VVVVVVVV rrrrXXXX XXYYYYYY SSSSSSSS MMMMMMMM
T: entity type
V: entity variant
X: entity X-coord (cut to 6b)
Y: entity Y-coord (cut to 6b)
S: entity state
M: entity timer

r: room offset. At start of entity serialization, ROOM index is initialized to 0.
For each entity serialized:
  `ROOM += r`
We can skip more than 15 rooms ahead by encoding entities with type `0`
We can encode a termination value with T=0, r=0

With this, we'd be able to have three save slots on 32KB SRAM, but we'd run some risks.
I'd hate for the trapdoor to next floor to not be serialized. Maybe we need a priority system?

## Reducing limits

Base isaac generates up to 25 rooms, assuming:
  - no curse of the labyrinth
  - no curse of the lost
  - not the void floor
Could probably halve `MAX_MAP_SLOTS` to `32`, leaving space for 24 normal rooms,
a devil/angel room, a secret room, an error room, plus a few extra.
I doubt I will implement curses or the void.

Could also limit to 16 entities per room instead. Or, have a global entity limit
with entities shuffled together and stable-sorted by some kind of priority system.

  32B - map tile type
  32B - map tile flag
  12B - RNG state
   1B - used slots
  32B - room slot -> map tile
  32B - room types
  64B - doors
   6B - room locations
   3B - pickups
  16B - health
 256B - items
  64B - room def
  64B - room RNG
3072B - tiles
= 3686B total without entities
reserve 4KB for entities (682 total - 21 per room-ish) 