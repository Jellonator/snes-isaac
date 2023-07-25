## Sprite slot allocation

Assume maximum of 32 objects + player, average two each? = about 64 sprites
 - ~16 enemies
 - up to 16 other: bombs, pickups, machines/beggars, etc.
 - up to ~4 familiars?
maybe just bump up to 48/64? :(
Reserve remaining 64 sprites for projectiles and simple objects

All objects will attempt to display themselves normally;
projectiles will use remaining sprite slots as necessary, which may lead to
flashing.

Have to keep in mind the serialization cost:
* Need minimum of 16 objects
    - can load enemies straight from room ROM data
* need position (2 bytes for X/Y? could use 1 byte to just store tile pos)
* need 1b type + 1b variant
* Maybe 1/2b extra data?
* (upper bound) 6B * 32obj * 160rooms = 30,720B
* (lower bound) 5B * 16obj *  48rooms =  3,840B
* (likely)      6B * 24obj *  64rooms =  9,216B
