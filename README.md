# Git Shard

Git shard is a tool for publishing multiple small Git repositories from one single big Git repository, without having to handle many git submodules.

# Installation

Download [git-shard](git-shard) and make sure the script is both in your `PATH` and executable (ex: `wget https://raw.githubusercontent.com/CromFr/git-shard/master/git-shard -O /usr/local/bin/git-shard && chmod +x /usr/local/bin/git-shard`)

# Usage

```bash
# Register lib/official as being a shard published on github
git shard init lib/official --upstream git@github.com:Drizzt/official-lib.git

# Register lib/experimental as being a shard that is not currently published
git shard init lib/experimental

# List all registered shards
git shard list

# Remove a shard
git shard remove lib/experimental

# Copy commits from the main repository into each registered shard, if the shard is affected by any change
git shard commit

# Execute git commands inside specific shard repositories
git shard exec lib/official log --format=oneline

# Execute git commands inside all shard repositories
git shard exec "*" push origin master

# Limit the shard "secrets" to only a set of files and directories. Paths are relative to the shard path.
git shard files secrets add "*.md"
git shard files secrets add public-1/
```


# More info

- Shards are stored inside `.git/shards/<path of the shard>`
- Shard registration is managed inside the git config (`.git/config`)
- The main repository is cleaned with git-stash during the `git shard commit` process. If something went wrong, you can retrieve your modifications with `git stash pop`.