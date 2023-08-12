OBJDIR   := obj
BINDIR   := bin
SRCDIR   := src
BINFILE  := Test.sfc
AC       := wla-65816
ALINK    := wlalink
AFLAGS   := -I include
ALDFLAGS := -S -v
PY       := python3

SOURCES  := main.asm\
			init.asm\
			player.asm\
			layout.asm\
			mapgenerator.asm\
			render.asm\
			rng.asm\
			map.asm\
			bindata.asm\
			vqueue.asm\
			spriteslot.asm\
			spritedefs.asm\
			entity.asm\
			projectile.asm\
			entity/enemy_fly.asm\
			entity/enemy_zombie.asm

OBJECTS  := $(SOURCES:%.asm=$(OBJDIR)/%.obj)
PALETTES := $(wildcard assets/palettes/*.hex)
SPRITES  := $(wildcard assets/sprites/*.raw)
INCLUDES := $(wildcard include/*.inc) include/assets.inc

Test.smc: Test.link $(OBJECTS)
	mkdir -p $(BINDIR)
	$(ALINK) $(ALDFLAGS) Test.link $(BINDIR)/$(BINFILE)

Test.link:
	echo -e -n "[objects]$(OBJECTS:%.obj=\n%.obj)" > Test.link

include/assets.inc: $(PALETTES) $(SPRITES) assets/palettes.json assets/sprites.json
	echo MAKING ASSET INC
	mkdir -p include/palettes/
	mkdir -p include/sprites/
	$(PY) scripts/assetimport.py

$(OBJDIR)/%.obj: $(SRCDIR)/%.asm $(INCLUDES)
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
