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
    * [ ] (basement) Monstro
    * [ ] (basement) Duke of Flies

## OTHER

- [ ] Optimize ground decor system for more complex shapes
- Improve screen transition
    * [ ] Fix jankiness of how entities are scrolled off the screen.
    * [ ] Don't load entities into room until room is fully scrolled into view,
        to prevent sprites from being drawn incorrectly during loading.
        or we could pause the vqueue until transition finishes, but this might
        backfire.
    * [ ] Allow screen transitions to differing tilesets (e.g., secret rooms
        and devil deals can have their own tilesets and palettes). This may require
        some trickery. Ideas:
        * Idea 1: If tileset differs between both rooms: first, load new tileset into
          unused vram space. Then, use HDMA to swap BG2 pointer between transition.
          This would only work for vertical transitions, and requires two extra pages
          of vram to be set aside. I suppose the unused page of sprite data could
          be used, as it is unused until enemies load. I suppose horizontal transitions
          could work, but we'd have to f-blank mid-screen, which is bad. Also no way to
          deal with palettes.
        * Idea 2: First, scroll background out of frame. When it is completely out of frame,
          then we can load palettes and character data. Advantages: First, loading is
          entirely off-screen, so we can do this horizontally as well as vertically.
          Second, we could load entities during the transition, so that they are
          displayed (and potentially scrolled into view) during the second half of
          the transition.
          The disadvantage is that there is extra loading time between rooms, extra
          space that the scrolling must occur over, and a period where the screen
          will be completely black. This would make the rooms 'feel' further apart.
          We could opt to only do this for special rooms.
          We currently use 32 frames to transition. Double this is 64 frames.
          We could instead move at double the speed, which could work.
        * Idea 3: we disable the UI during the transition, and use BG1 to
          display the newly loaded room. We can use the palettes that the UI *was*
          using for the new room. When the transition finishes, we swap all of the
          new room's data back to BG2, and reload and re-enable the UI.
          A few extra frames will be needed for all of the memory swapping;
          one frame to upload the 4KB of the new rooms' character data into BG1.
          one frame to upload the 4KB of UI data back into BG1.
          one frame to upload the 4KB of the new rooms' character data into BG2.
          This lacks the advantage of Idea 2's easier entity display capabilities,
          but it's not like it would be impossible to do so.
            * Side note: we could skip *some* of these extra frames by simply just
              keeping BG1 and BG2 swapped, and using BG2 as the UI sometimes.
              Though we face some priority issues if we do this, so lets not.
        * Idea 4: similar to idea 3. Except, we keep the UI.
          new tiles are loaded into the third and fourth pages of BG2, and we offset
          all tile indices written to BG2's tilemap for the new room. Palettes are
          a problem here, however.
        * Idea 5: sprites. Use sprites for the newly loaded room, until it reaches
          halfway point. Then put newly loaded room into BG2, and use sprites to
          represent the previously loaded room. I hate this idea. Also makes
          displaying isaac, and entities in old/new room difficult.
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