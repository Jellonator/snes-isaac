OBJDIR  := obj
BINDIR  := bin
SRCDIR  := src
BINFILE := Test.smc
AC      := wla-65816
ALINK   := wlalink
AFLAGS  := -I include
ALFLAGS := -S
PY      := python3

SOURCES := src/main.asm
OBJECTS := obj/main.obj
PALETTES := $(wildcard assets/palettes/*.hex)
SPRITES := $(wildcard assets/sprites/*.raw)

Test.smc: src/main.asm Test.link $(OBJECTS)
	mkdir -p $(BINDIR)
	$(ALINK) $(ALFLAGS) Test.link bin/Test.smc

include/assets.inc: $(PALETTES) $(SPRITES) assets/palettes.json assets/sprites.json
	$(PY) scripts/assetimport.py

$(OBJDIR)/%.obj: $(SRCDIR)/%.asm include/assets.inc
	mkdir -p $(OBJDIR)
	$(AC) $(AFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -rf $(BINDIR)
	rm -rf include/palettes/
	rm -rf include/sprites/