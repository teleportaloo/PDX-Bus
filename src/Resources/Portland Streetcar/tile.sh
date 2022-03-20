#!/bin/bash
# This shell script will make the tiles used to display the Streetcar map.
# You will need to install ImageMagick to get the "convert" executable, I did it
# using MacPorts:
#   sudo port install ImageMagick
file=StreetcarMap.gif
function tile() {
/opt/local/bin/convert $file -scale ${s}%x -crop 256x256 \
-set filename:tile "%[fx:page.x/256]_%[fx:page.y/256]" \
+repage +adjoin "${file%.*}/${file%.*}_${s}_%[filename:tile].${file#*.}"
}
s=100
tile
s=50
tile
s=25
tile
