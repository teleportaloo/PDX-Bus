all: StreetcarMap/StreetcarMap_100_0_0.gif

install: all

StreetcarMap/StreetcarMap_100_0_0.gif: StreetcarMap.gif
	rm -r StreetcarMap || true 
	mkdir StreetcarMap
	./tile.sh


clean:
	rm -r StreetcarMap || true 

