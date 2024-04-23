## MAPGEN

Essentials:
- [ ] Special rooms (item, shop, boss, start)
    * [X] Implement room pools for special room types
    * [X] Starting room
    * [X] item room (semi-implemented; need items first)
    * [ ] shop room (semi-implemented; need items, pickups, and coins first)
    * [ ] boss room (semi-implemented; need bosses first)
- [X] Door types and open methods (e.g. lock the item room; don't open doors until enemies are defeated)
    * [X] Implement door flags/enums
    * [X] Prevent player from entering closed doors
    * [X] Close doors when entering combat rooms
    * [X] Open certain doors after defeating all enemies
    * [X] Give different visuals to different door types
    * [X] Allow door states/visuals to change mid-room
    * [X] Door type depends on room type
- [ ] Might need to keep better track of end room locations / generate them if they don't already exist
- [ ] Save entity data when leaving a room
- [X] Don't respawn enemies for completed rooms
- [ ] Items
    * [X] Item rooms contain item pedestal
    * [X] Player can pick up items
    * [X] Items with basic stat effects
    * [X] on-pickup items (e.g. health up)
    * [ ] Items with effects
    * [ ] Active Items
    * [X] Item pools
- [ ] Bosses
    * [X] Implement basic boss
    * [ ] Implement an actual boss with AI
    * [X] Room should spawn an item after completing
    * [ ] Room should spawn entrance to next floor after completing

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
- [ ] Change up map generation depending on floor type (e.g. room layouts specific to floors)
    * [ ] Certain special rooms (i.e. boss rooms) change pools depending on floor
    * [ ] Swap tiles/palette depending on floor
- [ ] Player costumes
    * [ ] RAM buffer
    * [ ] sprite overlay