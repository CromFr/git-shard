# Git Shard

![Git-shard tests](https://github.com/CromFr/git-shard/workflows/Git-shard%20tests/badge.svg)

Git shard is a tool for publishing multiple small Git repositories from one single big Git repository, without having to handle many git submodules.

# Installation

Download [git-shard](git-shard) and make sure the script is both in your `PATH` and executable (ex: `wget https://raw.githubusercontent.com/CromFr/git-shard/master/git-shard -O /usr/local/bin/git-shard && chmod +x /usr/local/bin/git-shard`)

# Usage

```bash
# Print help
git shard -h
git shard init -h

# Register lib/experimental as being a shard that is not currently published
git shard init lib/experimental

# Register lib/official as being a shard already published on github
git shard init lib/official --clone git@github.com:Drizzt/official-lib.git

# List all registered shards
git shard list

# Remove a shard
git shard remove lib/experimental

# Copy commits from the main repository into each registered shard, if the shard is affected by any change
git shard push

# Copy commits new commits from each shard into the main repository
git shard pull

# Execute git commands inside specific shard repositories
git shard exec lib/official log --format=oneline

# Execute git commands inside all shard repositories
git shard exec "*" push origin master

# Limit the shard "secrets" to only a set of files and directories. Paths are relative to the shard path.
git shard files secrets add "*.md"
git shard files secrets add public-1/



```
# Examples
### Publish shard commits
```bash
# Copy commits to shards
git shard push

# Push commits to the shard remotes
git shard exec "*" push origin master
```

### Merge a pull request in a shard
```bash
# First, pull and merge pull request changes
# Alternatively you can merge using Github interface and execute `git shard
# exec lib/official pull` tu pull the PR commits)
git shard exec lib/official pull https://github.com/user/official-lib master

# Then pull commits into the main repo
git shard pull lib/official
```

# More info

- Shards are stored inside `.git/shards/<path of the shard>`
- Shard registration and state is stored inside the local git config (`.git/config`)
- The main repository is cleaned with git-stash during the `git shard push` process. If the command runs successfully, the stash is automatically popped, but if something went wrong, you can re-apply your modifications and untracked files with `git stash pop`.