all: MAXWESMap/MAXWESMap_100_0_0.gif

install: all

MAXWESMap/MAXWESMap_100_0_0.gif: MAXWESMap.gif
	rm -r MAXWESMap || true
	mkdir MAXWesMap
	./tile.sh

clean:
	rm -r MAXWESMap || true

