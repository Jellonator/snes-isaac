# TODO

## MAPGEN

- Room types
    * Shops
        * [X] Purchasable pickups
        * [X] Purchasable items
        * [X] Shopkeeper
        * [ ] Restock machine
    * Secret rooms
        * [X] Dedicated bombable wall textures
        * [X] Room pool
    * [ ] Sacrifice rooms
    * [ ] Cursed rooms
    * [ ] Arcade rooms
    * [ ] Challenge rooms
- [X] Update RNG on next floor
- [X] Set reward RNG to be based on room
- [ ] Change up map generation depending on floor type (e.g. room layouts specific to floors)
    * [ ] Certain special rooms (i.e. boss rooms) change pools depending on floor

## ITEMS

- [X] Active Items

## ENEMIES

- [X] Zombie
    * [X] Animated body
    * [X] Random movement when headless
- Pathfinding
    * [X] Diagonal Movement
    * [X] Target player when within player tile

## BOSSES

- Bosses
    * [ ] (basement) Finish Monstro
    * [ ] (basement) Finish Duke of Flies

## OTHER

- [ ] Optimize ground decor system for more complex shapes
- [X] Improve screen transition
    * [X] Fix jankiness of how entities are scrolled off the screen.
    * [X] Allow screen transitions to differing tilesets (e.g., secret rooms
        and devil deals can have their own tilesets and palettes).
- [X] Player costumes
    * [ ] sprite overlay
- [ ] Bomb adds velocity to hit objects
- [ ] Bombs receive velocity from projectiles
- [ ] Pickups have collision, can push each other
- [ ] Find empty spots for newly dropped pickups
- [X] Make minimap into 7x7 local preview
- [X] Pause menu
    * [X] Show full minimap in pause menu
    * [ ] Show item collection in pause menu
    * [ ] Cheats in pause menu
    * [X] Show stats in pause menu
    * [X] Save and quit