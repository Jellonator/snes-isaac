# Animations

## Issue: need to animate enemy/object sprites
Sprites will need to be updated on-the-fly as they are needed.

Problem: Different objects of same type may or may not use same sprite image at same time.

Up to 128 sprites, of which VRAM can have up to 128 16x16 sprites.

Problem: we're using first sprite bank for 'known' sprites, such as player, bombs, etc.

Problem: Can't upload entire 16K of sprite data every frame (up to ~5K per frame)

Important: Sprite frames may only need to update every few frames, and most
objects don't need complex animation (e.g. projectiles).

Expect up to roughly 16 animated objects with four 16x16 tiles each. In such
rooms, most enemies are likely to be similar.

## Idea: sprite animation system

Every sprite has a 16b ID

Every sprite has a type

### Sprite types

#### Static

Single sprite, never updated.
Loaded when first object of type spawns,
unloaded when last object of type is removed.

#### Static animated

Single sprite with many frames, continuously updated.
Loaded when first object of type spawns,
unloaded when last object of type is removed.

Two params:
 * number of animation frames (1B)
 * number of frames per frame (1B)

#### Dynamic frames

Single sprite with many frames, each frame of which has own ID.
Loaded when object requests it.
Unloaded when all objects unrequest it.
Similar to reference counting

### Ideal

* Room begins
* Load objects
    * Enemy 1 loads static sprites
    * Enemy 2 loads static sprites
* Update loop
    * Enemy 1 updates, uses static sprite
    * Enemy 2 updates, uses dynamically loaded sprite
* Render loop
    * Enemy 2's sprite isn't loaded, must be loaded
        * Find empty sprite slot
        * If no empty sprite slots, overwrite least recently used sprite slot

In memory, store relation of sprite IDs to their location in cache.
If zero, then sprite is unloaded. Run routine to load sprite.

## Idea 2: Entity-managed system

Two types of slots: entity variant slots, and entity slots
Both entity variants and entities themselves may request VRAM space

When entity loads, it checks entity variant table, and loads entity variant if
necessary.