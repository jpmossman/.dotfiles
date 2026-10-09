#!/usr/bin/env bash
# Create a throwaway test machine for one profile:
#   test/orb/create.sh <personal|work|work-headless>
# Isolated = no /Users sharing and no `mac` integration. The only host paths it
# sees are this repo (/src/dotfiles) and, for work profiles, the private work
# layer next to it (/src/dotfiles-work, or $WORK_DIR).
set -euo pipefail
PROFILE=${1:?usage: create.sh <profile>}
MACHINE=mise-dotfiles-test-$PROFILE
REPO=$(cd "$(dirname "$0")/../.." && pwd)
WORK_DIR=${WORK_DIR:-$REPO/../.dotfiles-work}

if orb list -q 2>/dev/null | grep -qx "$MACHINE"; then
  echo "machine '$MACHINE' already exists; run test/orb/destroy.sh $PROFILE first" >&2
  exit 1
fi
mounts=(--mount "$REPO:/src/dotfiles")
# personal machines never get to see the work layer
if [[ $PROFILE == work* ]] && [ -d "$WORK_DIR" ]; then
  mounts+=(--mount "$(cd "$WORK_DIR" && pwd):/src/dotfiles-work")
fi
orb create --isolated "${mounts[@]}" ubuntu:noble "$MACHINE"
orb -m "$MACHINE" uname -a
