# History rewrite: rename occurrences

On 2026-01-13 UTC I rewrote commit messages to replace `anthonyware-arch` → `anthonyware` across repository history to remove the old repo name from messages and refs.

A backup branch was created: `backup/pre-rename-20260113T105312Z` which points to the pre-rewrite history.

Commands run (summary):

- `git branch backup/pre-rename-20260113T105312Z`
- `git filter-branch --msg-filter 'sed -e "s/anthonyware-arch/anthonyware/g"' -- --all`
- `git push --force --all && git push --force --tags`

If you are a collaborator, please re-clone or run the commands below to resynchronize local clones:

```
# Option A: re-clone (recommended)
# git clone https://github.com/rockandrollprophet/anthonyware.git

# Option B: update an existing local clone (careful, this rewrites history):
# git fetch origin
# git checkout main
# git reset --hard origin/main
```

If you'd like I can also publish a mapping of old -> new commit SHAs; reply to request it.
