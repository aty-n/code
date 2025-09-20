# github sync guide

this folder is linked to: `https://github.com/aty-n/code`  
default branch: `main`

## one-time setup

configure your identity:
```bash
git config --global user.name "your name"
git config --global user.email "you@example.com"
```

authenticate with github (private repos):
```bash
gh auth login --hostname github.com --git-protocol https
gh auth setup-git
```

if you prefer ssh, make sure your key is added to github and reachable by the agent.

## everyday workflow

**check status**
```bash
git status
```

**pull latest**
```bash
git pull --rebase origin main
```

**stage, commit, push**
```bash
git add -A
git commit -m "message"
git push origin main
```

**see history**
```bash
git log --oneline --graph --decorate --all
```

## tips

- first-time push may need an upstream:
```bash
git push -u origin main
```

- switch branches:
```bash
git checkout <branch>
```

- create a new branch:
```bash
git checkout -b <new-branch>
git push -u origin <new-branch>
```

- discard local changes (careful):
```bash
git restore --staged .
git restore .
```

## shortcuts provided

in `./bin` there are helper scripts:

- `bin/sync-status` → `git status`
- `bin/sync-pull`   → `git pull --rebase origin main`
- `bin/sync-push`   → `git add -A && git commit -m "<msg>" && git push origin main`

usage:
```bash
./bin/sync-status
./bin/sync-pull
./bin/sync-push "update docs"
```

(optionally add `./bin` to your path.)
