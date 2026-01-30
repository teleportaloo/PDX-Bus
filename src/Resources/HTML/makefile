all: ../../Tables/StreetcarHotSpotTable.def ../../Tables/MaxHotSpotTable.def

install: all

../../Tables/StreetcarHotSpotTable.def: streetcar.html
	./convert.sh streetcar.html ../../Tables/StreetcarHotSpotTable.def 1

../../Tables/MaxHotSpotTable.def: railmap.html
	./convert.sh railmap.html ../../Tables/MaxHotSpotTable.def 0

clean:
	rm ../../Tables/StreetcarHotSpotTable.def || true
	rm ../../Tables/MaxHotSpotTable.def || true
