#!/usr/bin/env bash
# Run install.sh for one profile inside its machine; log to .sandbox/logs/<profile>.log.
#   test/orb/run.sh <profile>
# The VM clones the repos, so only committed changes are tested.
set -euo pipefail
PROFILE=${1:?usage: run.sh <profile>}
MACHINE=mise-dotfiles-test-$PROFILE
REPO=$(cd "$(dirname "$0")/../.." && pwd)
LOGS="$REPO/.sandbox/logs"
mkdir -p "$LOGS"

for r in "$REPO" "$REPO/../.dotfiles-work"; do
  if [ -d "$r/.git" ] && [ -n "$(git -C "$r" status --porcelain)" ]; then
    echo "warning: uncommitted changes in $r are NOT part of the test" >&2
  fi
done

# GitHub token goes over stdin so it never appears in a process list or log.
gh auth token | orb -m "$MACHINE" bash /src/dotfiles/test/orb/in-vm.sh "$PROFILE" >"$LOGS/$PROFILE.log" 2>&1
summary=$(sed -n '/^===== SUMMARY/,$p' "$LOGS/$PROFILE.log")
echo "$PROFILE: $(grep -c ' rc=0 ' <<<"$summary") ok, $(grep -cE ' rc=[1-9]' <<<"$summary") failed  ($LOGS/$PROFILE.log)"
grep -E ' rc=[1-9]' <<<"$summary" || true
