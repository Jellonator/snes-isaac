## MAPGEN

Essentials:
- [ ] Special rooms (item, shop, boss, start)
    * [X] Implement room pools for special room types
    * [X] Starting room
    * [X] item room (semi-implemented; need items first)
    * [ ] shop room (semi-implemented; need items, pickups, and coins first)
    * [X] boss room (semi-implemented; need bosses first)
- [X] Door types and open methods (e.g. lock the item room; don't open doors until enemies are defeated)
    * [X] Implement door flags/enums
    * [X] Prevent player from entering closed doors
    * [X] Close doors when entering combat rooms
    * [X] Open certain doors after defeating all enemies
    * [X] Give different visuals to different door types
    * [X] Allow door states/visuals to change mid-room
    * [X] Door type depends on room type
    * [ ] Keys
    * [ ] Locked doors able to be opened with keys
- [X] Might need to keep better track of end room locations / generate them if they don't already exist
- [X] Fix bug where player can spawn in boss room. This happens when the spawn room is an endroom, and is able to be selected as the boss room. Potential fixes: remove spawn room from end room pool, or move spawn room if it was taken.
- [X] Save entity data when leaving a room
- [X] Don't respawn enemies for completed rooms
- [ ] Items
    * [X] Item rooms contain item pedestal
    * [X] Player can pick up items
    * [X] Items with basic stat effects
    * [X] on-pickup items (e.g. health up)
    * [X] Items with effects
    * [ ] Active Items
    * [X] Item pools
- [ ] Bosses
    * [X] Implement basic boss
    * [ ] Implement an actual boss with AI
    * [X] Room should spawn an item after completing
    * [X] Room should spawn entrance to next floor after completing
- [ ] Update RNG on next floor
- [ ] Set reward RNG to be based on room
- [X] Bombs
- [X] Hide map rooms until revealed
- [X] Darken unexplored map rooms
- [ ] Optimize ground decor system for more complex shapes
- [ ] Improve screen transition

Bonus:
- [ ] Secret rooms with bombable walls
- [X] Room rewards
    * [X] Only for combat rooms
    * [X] Only directly after completing a room
- [ ] More special rooms
    * [ ] Secret
    * [ ] Sacrifice
    * [ ] Cursed
    * [ ] Arcade
    * [ ] Challenge
- [ ] Change up map generation depending on floor type (e.g. room layouts specific to floors)
    * [ ] Certain special rooms (i.e. boss rooms) change pools depending on floor
    * [X] Swap tiles/palette depending on floor
- [X] Player costumes
    * [X] RAM buffer
    * [ ] sprite overlay
- [ ] Bomb adds velocity to hit objects
- [ ] Bombs receive velocity from projectiles
- [ ] Pickups have collision, can push each other
- [ ] Find empty spots for newly dropped pickups