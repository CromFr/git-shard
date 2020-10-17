#!/bin/bash

set -exuo pipefail
export PATH="$PWD:$PATH"

rm -rf "$(dirname "$0")/test/"
mkdir "$(dirname "$0")/test"
cd "$(dirname "$0")/test"

git shard -h >/dev/null
git shard init -h >/dev/null
git shard remove -h >/dev/null
git shard files -h >/dev/null
git shard commit -h >/dev/null
git shard exec -h >/dev/null

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
echo "Exclude this" > "RestrictedProject/yolo"

git shard files RestrictedProject add "MATCH*"
git shard files RestrictedProject add "yolo"
git shard files RestrictedProject remove "yolo"
git shard files RestrictedProject add "SPACED NAME*"

git add .
git commit --no-gpg-sign -m "Added restricted project"
git shard commit --no-gpg-sign
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))


echo "===================================================== RootShard"

git shard init .
git shard files . add README.md
git shard commit --no-gpg-sign
(( $(git shard exec . show --pretty="" --name-only HEAD | wc -l) == 1))

git shard remove .

# check that the removal didn't do anything nasty
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))



echo "===================================================== BranchShard"

git branch branch-repo

mkdir BranchRepo
echo "This shard tracks a specific branch of the main repo" > BranchRepo/README.md
git shard init --branch branch-repo BranchRepo/

git shard commit --no-gpg-sign
git shard exec BranchRepo show HEAD && exit 1 # No commits

git checkout branch-repo
git shard commit --no-gpg-sign
git shard exec BranchRepo show HEAD && exit 1 # No commits

git add .
git commit --no-gpg-sign -m "Added branched shard"

git checkout branch-repo
git shard commit --no-gpg-sign
(( $(git shard exec BranchRepo show --pretty="" --name-only HEAD | wc -l) == 1))

(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))


(( $(git shard list | wc -l) == 5))

echo "SUCCESS ! :)"

