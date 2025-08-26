# This script takes the HTML and replaces some sequences with C macros
# so that this can be used to create static tables for the hotspots

echo $1 $2

cp $1 $2
# Remove the parts of the file before and after the map
sed -i "" -n '/\<map name/,$p' $2
sed -i "" -e '/\<map name/d' $2
sed -i "" -e '/\<\/map/,$d' $2

# Do the rects first as we have to be careful to only change the
# items that are rects as the same sequences are replaced differently
# for the polygons
sed -i "" -e 's/\<area shape=\"rect\" coords=\"/HS_RECT(  /g' $2
sed -i "" -e '/HS_RECT/s/\/\>/)/g' $2
sed -i "" -e '/HS_RECT/s/\" href=/,/g' $2

# Polygons are done last now with simple replaces
sed -i "" -e 's/\<area shape=\"poly\" coords=\"/HS_POLY( (/g' $2
sed -i "" -e 's/\" href=/ ), /g' $2
sed -i "" -e 's/\/\>/)/g' $2
# Align the first quote on 80 characters
awk 'BEGIN {FS=OFS="\""} {$1 = sprintf("%-80s", $1)} 1' $2 > $2.txt
mv $2.txt $2

# Add the comment and license to the file
(echo '/* Original HTML file:' $1 '*/'; cat prefix.txt ; cat $2) > $2.tmp
mv $2.tmp $2

