Test.smc: src/main.asm Test.link
	mkdir -p bin
	mkdir -p obj
	python3 scripts/assetimport.py
	wla-65816 -I include -o obj/main.obj src/main.asm
	wlalink -S Test.link bin/Test.smc

clean:
	rm -rf bin/
	rm -rf obj/
	rm -rf include/palettes/
	rm -rf include/sprites/