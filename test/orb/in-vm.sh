#!/usr/bin/env bash
# Single-quoted commands below expand in the inner shell, on purpose.
# shellcheck disable=SC2016
# Runs INSIDE an isolated OrbStack machine, as the default user, on a fresh
# Ubuntu image. Pipes install.sh into sh exactly like the README one-liner,
# then checks the result and re-runs for idempotency. Every step runs even if
# an earlier one fails; the summary at the end lists exit codes.
set -uo pipefail
PROFILE=$1
read -r GITHUB_TOKEN || true
export GITHUB_TOKEN
export DOTFILES_REPO=/src/dotfiles
[ -d /src/dotfiles-work ] && export WORK_REPO=/src/dotfiles-work
# The mounts are owned by the host uid; let git read them without touching a
# config file (~/.config/git is one of the things under test).
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*'
cd "$HOME" || exit 1

declare -a SUMMARY=()
step() {
  local name=$1; shift
  printf '\n===== %s =====\n$ %s\n' "$name" "$*"
  local start=$SECONDS
  "$@"; local rc=$?
  SUMMARY+=("$(printf '%-16s rc=%-3s %4ss' "$name" "$rc" "$((SECONDS - start))")")
  return 0
}
z() { zsh -ic "$1" 2>&1 | sed 's/^\x1b\[5 q//'; return "${PIPESTATUS[0]}"; }

# Public expectations; the private work layer adds its own (tool names, git
# email domain) in test/expect.sh, so none of that appears in this repo.
expect_tools="rg eza gopls cmake arm-none-eabi-gcc clang probe-rs"
expect_email=gmail.com
[ "$PROFILE" = work-headless ] && expect_tools=${expect_tools/ clang/}
if [ -n "${WORK_REPO:-}" ] && [ -f "$WORK_REPO/test/expect.sh" ]; then
  # shellcheck source=/dev/null
  . "$WORK_REPO/test/expect.sh"
fi

step install      sh -c 'cat /src/dotfiles/install.sh | sh -s -- "$1"' _ "$PROFILE"
step miserc       cat "$HOME/.config/mise/miserc.toml"
step modules      sh -c 'cd ~ && ~/.local/bin/mise config ls | awk "{print \$1}"'
step dot-status   sh -c 'cd ~ && ~/.local/bin/mise dotfiles status | grep -v "^ "'
step missing      sh -c 'cd ~ && ~/.local/bin/mise ls --missing'
step git-identity sh -c "e=\$(git config --get user.email); echo \"\$e\"; case \$e in *@$expect_email) ;; *) exit 1 ;; esac"
step tools        z 'rc=0; for t in '"$expect_tools"'; do p=$(command -v $t) && echo "$t  $p" || { echo "$t  MISSING"; rc=1; }; done; exit $rc'
step no-extras    z 'case '"$PROFILE"' in personal) [ ! -e ~/.config/mise/conf.d/work ] ;; work-headless) [ ! -e ~/.config/wezterm ] ;; *) true ;; esac'
step shell        z 'echo "login shell: $(getent passwd $USER | cut -d: -f7)"; type source_creds 2>/dev/null || echo "no source_creds"'
step rerun        sh -c 'cat /src/dotfiles/install.sh | sh -s -- "$1"' _ "$PROFILE"
step plan-clean   sh -c 'cd ~ && ~/.local/bin/mise bootstrap plan --detailed-exitcode'
step repo-clean   sh -c 'git -C ~/.config/mise status --short --ignored | grep -vE "miserc.toml|conf.d/work/" ; true'

printf '\n===== SUMMARY (%s) =====\n' "$PROFILE"
printf '%s\n' "${SUMMARY[@]}"
