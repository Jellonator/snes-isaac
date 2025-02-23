 160B - map tile type
 160B - map tile flag
  12B - RNG state
   1B - used slots
 ~~160B - map tile -> room slot~~ - dont need; can just reverse room slot -> map tile
  64B - room slot -> map tile
  64B - room types
 320B - doors
   6B - room locations
   3B - pickups
  16B - health
 256B - items
6144B - tile types
6144B - tile variants
 128B - room types
9216B - serialized entities
 128B - room RNG
= 22,822B per saved game

If I map tile types and their variants into a single byte of valid values,
I could maybe save 6K without issue.
Cutting down on serialized entities might not be feasible; if we only store
existing entities, we might run the risk of running out of space in cases where
the player has somehow spawned 24 serializable entities in every room. Maybe
save 1.5K by combining X and Y coordinates? Could also just hard-cap number of
serialized entities in save slot.