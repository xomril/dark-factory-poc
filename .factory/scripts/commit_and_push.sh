#!/usr/bin/env bash
# Commit everything and push to a factory branch. Refuses anything else
# (FACTORY_RULES.md §3: no direct main push, no force push).
#
# Credentials are NOT persisted in .git/config: the token is used only for
# this one push, via the remote URL on the command line.
#
# Usage: GH_TOKEN=... GH_REPO=owner/name commit_and_push.sh <branch> "<commit message>"
set -euo pipefail

BRANCH="${1:?branch}"; MESSAGE="${2:?message}"
: "${GH_TOKEN:?GH_TOKEN required}"; : "${GH_REPO:?GH_REPO required}"

if ! [[ "$BRANCH" =~ ^factory/issue-[0-9]+$ ]]; then
  echo "Refusing to push to '$BRANCH': only factory/issue-<number> is allowed." >&2
  exit 1
fi

# Ignore any hooks an agent may have planted in .git/hooks.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null

git config user.name  "dark-factory[bot]"
git config user.email "dark-factory@users.noreply.github.com"

git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit."
else
  git commit -m "$MESSAGE"
fi
git push "https://x-access-token:${GH_TOKEN}@github.com/${GH_REPO}.git" "HEAD:refs/heads/${BRANCH}"
