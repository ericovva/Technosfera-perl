cc -o templater main.c `perl -MExtUtils::Embed -e ccopts -e ldopts`
./templater Plugin text.txt ./
rm -r templater*
