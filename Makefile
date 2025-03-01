OBJDIR   := obj
BINDIR   := bin
SRCDIR   := src
BINFILE  := Test.sfc
AC       := wla-65816
ALINK    := wlalink
AFLAGS   := -I include
ALDFLAGS := -S -v
PY       := python3

SOURCES  := bindata.asm\
			consumables.asm\
			costume.asm\
			entity.asm\
			entity/bomb.asm\
			entity/effect.asm\
			entity/enemy_fly.asm\
			entity/enemy_zombie.asm\
			entity/enemy_cube.asm\
			entity/enemy_boss_duke_of_flies.asm\
			entity/enemy_boss_monstro.asm\
			entity/item_pedastal.asm\
			entity/pickup.asm\
			entity/shopkeeper.asm\
			entity/tileentity.asm\
			entity/trapdoor.asm\
			init.asm\
			floor.asm\
			game.asm\
			ground.asm\
			layout.asm\
			main.asm\
			math.asm\
			map.asm\
			menu.asm\
			mapgenerator.asm\
			overlay.asm\
			palettes.asm\
			player.asm\
			pathing.asm\
			playeritem.asm\
			projectile.asm\
			render.asm\
			rng.asm\
			room.asm\
			save.asm\
			spritedefs.asm\
			spriteslot.asm\
			vqueue.asm

OBJECTS  := $(SOURCES:%.asm=$(OBJDIR)/%.obj)
PALETTES := $(wildcard assets/palettes/*.hex)
SPRITES  := $(wildcard assets/sprites/*.raw)
TILEMAPS := $(wildcard assets/tilemaps/*.tmx)
INCLUDES := $(wildcard include/*.inc)

Test.smc: Test.link $(OBJECTS)
	mkdir -p $(BINDIR)
	$(ALINK) $(ALDFLAGS) Test.link $(BINDIR)/$(BINFILE)

Test.link:
	printf "[objects]$(OBJECTS:%.obj=\n%.obj)" > Test.link

include/roompools.inc: $(PALETTES) $(SPRITES) assets/rooms/roompools.json
	$(PY) scripts/roomimport.py

include/tilemaps.inc: $(PALETTES) $(SPRITES) assets/tilemaps.json
	mkdir -p include/tilemaps/
	$(PY) scripts/tilemapimport.py

include/assets.inc: $(PALETTES) $(SPRITES) assets/palettes.json assets/sprites.json
	mkdir -p include/palettes/
	mkdir -p include/sprites/
	$(PY) scripts/assetimport.py

$(OBJDIR)/%.obj: $(SRCDIR)/%.asm $(INCLUDES)
	mkdir -p $(OBJDIR)
	mkdir -p $(OBJDIR)/entity
	$(AC) $(AFLAGS) -o $@ $<

$(OBJDIR)/bindata.obj: $(SRCDIR)/bindata.asm $(INCLUDES) include/assets.inc include/roompools.inc include/tilemaps.inc
	mkdir -p $(OBJDIR)
	mkdir -p $(OBJDIR)/entity
	$(AC) $(AFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -rf $(BINDIR)
	rm -rf include/palettes/
	rm -rf include/sprites/
	rm -rf include/tilemaps/
	rm -f include/assets.inc
	rm -f include/roompools.inc
	rm -f include/tilemaps.inc
	rm -f Test.link
