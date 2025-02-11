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
			costume.asm\
			entity.asm\
			entity/bomb.asm\
			entity/effect.asm\
			entity/enemy_fly.asm\
			entity/enemy_zombie.asm\
			entity/enemy_boss_duke_of_flies.asm\
			entity/enemy_boss_monstro.asm\
			entity/item_pedastal.asm\
			entity/pickup.asm\
			entity/shopkeeper.asm\
			entity/trapdoor.asm\
			init.asm\
			floor.asm\
			ground.asm\
			layout.asm\
			main.asm\
			map.asm\
			mapgenerator.asm\
			palettes.asm\
			player.asm\
			playeritem.asm\
			projectile.asm\
			render.asm\
			rng.asm\
			room.asm\
			spritedefs.asm\
			spriteslot.asm\
			vqueue.asm

OBJECTS  := $(SOURCES:%.asm=$(OBJDIR)/%.obj)
PALETTES := $(wildcard assets/palettes/*.hex)
SPRITES  := $(wildcard assets/sprites/*.raw)
INCLUDES := $(wildcard include/*.inc)

Test.smc: Test.link $(OBJECTS)
	mkdir -p $(BINDIR)
	$(ALINK) $(ALDFLAGS) Test.link $(BINDIR)/$(BINFILE)

Test.link:
	echo -e -n "[objects]$(OBJECTS:%.obj=\n%.obj)" > Test.link

# include/roompools.inc: $(PALETTES) $(SPRITES) assets/rooms/roompools.json
# 	echo MAKING ROOMPOOL INC
# 	$(PY) scripts/roomimport.py

include/assets.inc: $(PALETTES) $(SPRITES) assets/palettes.json assets/sprites.json
	echo MAKING ASSET INC
	mkdir -p include/palettes/
	mkdir -p include/sprites/
	$(PY) scripts/assetimport.py

$(OBJDIR)/%.obj: $(SRCDIR)/%.asm $(INCLUDES)
	mkdir -p $(OBJDIR)
	mkdir -p $(OBJDIR)/entity
	$(AC) $(AFLAGS) -o $@ $<

$(OBJDIR)/bindata.obj: $(SRCDIR)/bindata.asm $(INCLUDES) include/assets.inc include/roompools.inc
	mkdir -p $(OBJDIR)
	mkdir -p $(OBJDIR)/entity
	$(AC) $(AFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -rf $(BINDIR)
	rm -rf include/palettes/
	rm -rf include/sprites/
	rm -f include/assets.inc
	rm -f include/roompools.inc
	rm -f Test.link
