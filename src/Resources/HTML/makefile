all: ../../Classes/StreetcarHotSpotTable.txt ../../Classes/MaxHotSpotTable.txt

install: all

../../Classes/StreetcarHotSpotTable.txt: streetcar.html
	./convert.sh streetcar.html ../../Classes/StreetcarHotSpotTable.txt

../../Classes/MaxHotSpotTable.txt: railmap.html 
	./convert.sh railmap.html ../../Classes/MaxHotSpotTable.txt

clean:
	rm ../../Classes/*StreetcarHotSpotTable.txt || true
	rm ../../Classes/*StreetcarHotSpotTable.txt || true
	rm ../../Classes/.*.txt || true

