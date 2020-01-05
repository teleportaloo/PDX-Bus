sed -i "" -e '/INSERT_LICENSE/ r license.c' "$1"
sed -i "" -e 's/\/\* INSERT_LICENSE \*\///g' "$1"
