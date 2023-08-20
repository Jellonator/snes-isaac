## MAPGEN

Short term:
- [ ] Special rooms (item, shop, boss, start)
    * [X] Implement room pools for special room types
    * [X] Starting room
- [ ] Door types and open methods (e.g. lock the item room; don't open doors until enemies are defeated)
    * [X] Implement door flags/enums
    * [X] Prevent player from entering closed doors
    * [ ] Close doors when entering combat rooms
    * [ ] Open certain doors after defeating all enemies
    * [ ] Give different visuals to different door types
    * [ ] Allow door states/visuals to change mid-room
    * [ ] Door type depends on room type
- [ ] Might need to keep better track of end room locations / generate them if they don't already exist
- [ ] Save entity data when leaving a room
- [ ] Don't respawn enemies for completed rooms

Long term:
- [ ] Secret rooms with bombable walls
- [ ] Room rewards
    * [ ] Only for combat rooms
    * [ ] Only directly after completing a room
- [ ] More special rooms
- [ ] Change up map generation depending on floor type (e.g. room layouts specific to floors)
    * [ ] Certain special rooms (i.e. boss rooms) change pools depending on floor
    * [ ] Swap tiles/palette depending on floor