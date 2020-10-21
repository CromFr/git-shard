#!/bin/bash

function errexit() {
  echo "TEST FAILURE@${BASH_SOURCE[1]}:${BASH_LINENO[0]} ${BASH_COMMAND}"
  exit 1
}
trap 'errexit' ERR
set -o errtrace

set -evuo pipefail
export PATH="$PWD:$PATH"

# Clean previous test dir
rm -rf "$(dirname "$0")/test/"
mkdir "$(dirname "$0")/test"
cd "$(dirname "$0")/test"

git shard -h >/dev/null
git shard init -h >/dev/null
git shard remove -h >/dev/null
git shard files -h >/dev/null
git shard push -h >/dev/null
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
git commit --no-gpg-sign -m "ProjectA: Appended readme"



################################################################################
# FirstRound
################################################################################

#################### Add some shards
git shard init ProjectA
git shard init ProjectB
git shard init lib/public-lib

#################### Push commits to shards
git shard push --no-gpg-sign
(( $(git shard exec ProjectA show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec ProjectB show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 2))

#################### Add one more commit
echo -e "\nThis is a super handy library" >> lib/public-lib/README.md
git add .
git commit --no-gpg-sign -m "lib/public-lib: Appended readme"

#################### Push commits to shards
git shard push --no-gpg-sign
(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 1))

#################### Should be noop
git config --local "shards.lib/public-lib.commit" ""
git shard push --no-gpg-sign
(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 1))



################################################################################
# RestrictedProject
################################################################################

#################### Add content
mkdir RestrictedProject
echo "Include this" > RestrictedProject/INC.md
echo "Exclude this" > RestrictedProject/EXC.md
echo "Not all files are included" > RestrictedProject/README.md

#################### Init shard and add files rules
git shard init RestrictedProject
git shard files RestrictedProject add INC.md
git shard files RestrictedProject add README.md

#################### Commit
git add .
git commit --no-gpg-sign -m "RestrictedProject: Added files"

#################### Push to shard
git shard push --no-gpg-sign
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 2))

#################### Add files
echo "Include this" > "RestrictedProject/MATCH with spaces.md"
echo "Include this" > "RestrictedProject/MATCH.md"
echo "Include this" > "RestrictedProject/SPACED NAME.md"
echo "Include this" > "RestrictedProject/SPACED NAME with more.md"
echo "Include this" > "RestrictedProject/SPACED NA.md"
echo "Exclude this" > "RestrictedProject/yolo"

#################### Add shard file rules
git shard files RestrictedProject add "MATCH*"
git shard files RestrictedProject add "yolo"
git shard files RestrictedProject remove "yolo"
git shard files RestrictedProject add "SPACED NAME*"

#################### Commit everything in main repo
git add .
git commit --no-gpg-sign -m "RestrictedProject: Added more files for pattern matching test"
#################### Push to shards
git shard push --no-gpg-sign

(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))



################################################################################
# RootShard
################################################################################

#################### Add root shard
git shard init .
git shard files . add README.md

#################### Push to shards
git shard push . --no-gpg-sign
(( $(git shard exec . show --pretty="" --name-only HEAD | wc -l) == 1))

#################### remove root shard
git shard remove .

#################### check that the removal didn't do anything nasty
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))
[ ! -d ".git/shards/__root" ]



################################################################################
# BranchShard
################################################################################

#################### Create new branch
git branch branch-repo

mkdir BranchRepo
echo "This shard tracks a specific branch of the main repo" > BranchRepo/README.md

#################### Add shard
git shard init --branch branch-repo BranchRepo/

#################### Should be noop
git shard push --no-gpg-sign
(git shard exec BranchRepo show HEAD >&/dev/null && exit 1) || true # No commits

#################### Checkout to branch
git checkout branch-repo
git shard push --no-gpg-sign
(git shard exec BranchRepo show HEAD >&/dev/null && exit 1) || true # No commits

#################### Commit
git add .
git commit --no-gpg-sign -m "Added branched shard"

#################### Should be noop
git shard push --no-gpg-sign
(git shard exec BranchRepo show HEAD >&/dev/null && exit 1) || true # No commits

#################### Push commit to branch shard
git checkout branch-repo
git shard push --no-gpg-sign
(( $(git shard exec BranchRepo show --pretty="" --name-only HEAD | wc -l) == 1))

(( $(git shard exec lib/public-lib show --pretty="" --name-only HEAD | wc -l) == 1))
(( $(git shard exec RestrictedProject show --pretty="" --name-only HEAD | wc -l) == 4))

(( $(git shard list | wc -l) == 5))

git checkout master



################################################################################
# Shard to main copy
################################################################################


#################### Add some commits in ProjectA
echo "This is a sample new file" > ProjectA/sample.txt
git shard exec ProjectA add sample.txt
git shard exec ProjectA commit --no-gpg-sign -m "$(echo -e "Added new file\n\nThis is a long commit message")" --author="John Doe <john.doe@dev.null>"
echo "Another line has been added" >> ProjectA/sample.txt
git shard exec ProjectA add sample.txt
git shard exec ProjectA commit --no-gpg-sign -m "One more line in sample.txt" --author="John Doe <john.doe@dev.null>"
rm ProjectA/sample.txt

#################### Try to copy impossible commit (applying HEAD requires HEAD^)
(( $(git log --format=%h | wc -l) == 5 ))
(git shard pull ProjectA --range "HEAD^-" --no-gpg-sign >& /dev/null && exit 1) || true
git am --abort

#################### Copy last commits in order
git shard pull ProjectA --no-gpg-sign
(( $(git log --format=%h | wc -l) == 7 ))

#################### Should be noop
git shard pull --no-gpg-sign
git shard pull '*' --no-gpg-sign
(( $(git log --format=%h | wc -l) == 7 ))




echo "SUCCESS ! :)"

