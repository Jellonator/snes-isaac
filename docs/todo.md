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
- [ ] Proper item pools;
    Item pools need to add no data to save games. My proposal:
    Items which are on the current floor will be excluded from the pool.
    Items which are in the player's inventory, and are not marked as duplicable,
    will be excluded from the pool.
    If the pool is empty, then add duplicable items to the pool, regardless of
    if the player has the item or not.
    If the pool is still empty, then we give a default item.
- [ ] Familiars
    * [ ] Followers - Brother bobby, sister maggy
    * [ ] Orbiters - Sacrificial dagger, cube of meat
    * [ ] 'conjoined' transformation. Except now we just merge familiars together.

## ENEMIES

- [X] Zombie
    * [X] Animated body
    * [X] Random movement when headless
- Pathfinding
    * [X] Diagonal Movement
    * [X] Target player when within player tile
- Caves Enemies

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
    * [-] Cheats in pause menu
        - [X] change floor
        - [ ] change room
        - [X] give/take item
        - [ ] give/take coins, bombs, keys
        - [ ] change pocket item
        - [ ] change trinket
        - [ ] spawn entities
    * [X] Show stats in pause menu
    * [X] Save and quit