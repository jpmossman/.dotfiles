#!/usr/bin/env bash
# Delete the test machine for one profile. Only ever touches mise-dotfiles-test-*.
set -euo pipefail
PROFILE=${1:?usage: destroy.sh <profile>}
orb delete --force "mise-dotfiles-test-$PROFILE"
