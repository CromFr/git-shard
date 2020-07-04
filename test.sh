#!/bin/bash

set -exuo pipefail

git init

echo "# Main project" > README.md

mkdir ProjectA
echo "# Project A" > ProjectA/README.md
mkdir ProjectB
echo "# Project B" > ProjectB/README.md
mkdir -p lib/public-lib
echo "# Official library" > lib/public-lib/README.md
echo "void lolmain(){}" > lib/public-lib/inc.cpp

git add .
git commit --no-gpg-sign -m "First commit !"

echo "I wanted to add this" >> ProjectA/README.md
git add .
git commit --no-gpg-sign -m "Appended project A readme"


echo "===================================================== FirstRound"

git shard init ProjectA
git shard init ProjectB
git shard init lib/public-lib

git shard commit --no-gpg-sign
(( $(git shard exec ProjectA show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec ProjectB show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 2))

echo -e "\nThis is a super handy library" >> lib/public-lib/README.md
git add .
git commit --no-gpg-sign -m "Appended project A readme"

git shard commit --no-gpg-sign
(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 1))



echo "===================================================== RestrictedProject"

mkdir RestrictedProject
echo "Include this" > RestrictedProject/INC.md
echo "Exclude this" > RestrictedProject/EXC.md
echo "Not all files are included" > RestrictedProject/README.md

git shard init RestrictedProject
git shard files RestrictedProject add INC.md
git shard files RestrictedProject add README.md

git add .
git commit --no-gpg-sign -m "Added restricted project"
git shard commit --no-gpg-sign
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 2))


echo "Include this" > "RestrictedProject/MATCH with spaces.md"
echo "Include this" > "RestrictedProject/MATCH.md"
echo "Include this" > "RestrictedProject/SPACED NAME.md"
echo "Include this" > "RestrictedProject/SPACED NAME with more.md"
echo "Include this" > "RestrictedProject/SPACED NA.md"

git shard files RestrictedProject add "MATCH*"
git shard files RestrictedProject add "yolo"
git shard files RestrictedProject remove "yolo"
git shard files RestrictedProject add "SPACED NAME*"

git add .
git commit --no-gpg-sign -m "Added restricted project"
git shard commit --no-gpg-sign
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))