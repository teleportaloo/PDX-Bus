all: ../../Tables/StreetcarHotSpotTable.c ../../Tables/MaxHotSpotTable.c

install: all

../../Tables/StreetcarHotSpotTable.c: streetcar.html
	./convert.sh streetcar.html ../../Tables/StreetcarHotSpotTable.c

../../Tables/MaxHotSpotTable.c: railmap.html
	./convert.sh railmap.html ../../Tables/MaxHotSpotTable.c

clean:
	rm ../../Tables/StreetcarHotSpotTable.c || true
	rm ../../Tables/MaxHotSpotTable.c || true
