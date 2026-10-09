#!/bin/sh
# Set up a machine from these dotfiles.
#
#   curl -fsSL https://raw.githubusercontent.com/jpmossman/dotfiles/main/install.sh | sh
#   curl -fsSL …/install.sh | sh -s -- work-headless
#
# Profiles (each is a list of mise config modules, see config.toml):
#   personal       my own machines            gui + personal + embedded
#   work           work laptop/desktop        gui + work + embedded
#   work-headless  throwaway VM, CI box, SSH  work + embedded
#
# Environment overrides:
#   DOTFILES_PROFILE  profile, instead of the first argument or a prompt
#   DOTFILES_REPO     this repo (default below; a local path works for testing)
#   WORK_REPO         private work layer to clone into conf.d/work (prompted if unset)
#   GITHUB_TOKEN      skip `gh auth login`; used for private repos and downloads
#   MISE_VERSION      mise release to install if mise is missing
#
# Safe to re-run: existing checkouts are kept, and files that would be replaced
# by a dotfile link are moved to ~/.dotfiles-backup/<timestamp>/ first.
set -eu

DOTFILES_REPO=${DOTFILES_REPO:-https://github.com/jpmossman/dotfiles.git}
MISE_VERSION=${MISE_VERSION:-v2026.9.15}
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/mise
PROFILE=${1:-${DOTFILES_PROFILE:-}}
WORK_REPO=${WORK_REPO:-}
BACKUP_DIR=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)

say() { printf '\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Under `curl | sh` stdin is this script, so prompts read the terminal directly.
has_tty() { { : </dev/tty; } 2>/dev/null; }
ask() {
  has_tty || die "$1 (no terminal to prompt on; pass it as an argument or env var)"
  printf '%s ' "$1" >/dev/tty
  read -r REPLY </dev/tty
}

modules_for() {
  case $1 in
    personal) echo "gui personal embedded" ;;
    work) echo "gui work embedded" ;;
    work-headless) echo "work embedded" ;;
    *) return 1 ;;
  esac
}

# --- 1. profile ---------------------------------------------------------------
if [ -z "$PROFILE" ]; then
  ask "Profile? [personal | work | work-headless]:"
  PROFILE=$REPLY
fi
MODULES=$(modules_for "$PROFILE") || die "unknown profile '$PROFILE'"
say "profile $PROFILE: modules $MODULES"

# --- 2. prerequisites: git, curl, tar, xz ------------------------------------
case $(uname -s) in
  Darwin)
    # git on a fresh Mac is a stub that wants the Command Line Tools.
    if ! xcode-select -p >/dev/null 2>&1; then
      xcode-select --install || true
      die "install the Xcode Command Line Tools (dialog opened), then re-run"
    fi
    ;;
  Linux)
    missing=""
    for c in git curl xz; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
    if [ -n "$missing" ]; then
      command -v apt-get >/dev/null 2>&1 || die "missing:$missing (no apt-get; install them first)"
      say "installing$missing"
      sudo apt-get update -qq
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates git curl xz-utils
    fi
    ;;
  *) die "unsupported OS: $(uname -s)" ;;
esac

# --- 3. mise ------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise >/dev/null 2>&1; then
  say "installing mise $MISE_VERSION"
  curl -fsSL https://mise.run | MISE_VERSION=$MISE_VERSION sh
fi
mise --version >&2

# --- 4. this repo -> ~/.config/mise -------------------------------------------
if [ -d "$CONFIG_DIR/.git" ]; then
  say "keeping existing checkout at $CONFIG_DIR ($(git -C "$CONFIG_DIR" remote get-url origin))"
else
  if [ -e "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR"
    say "moving existing $CONFIG_DIR to $BACKUP_DIR/"
    mv "$CONFIG_DIR" "$BACKUP_DIR/"
  fi
  say "cloning $DOTFILES_REPO"
  mkdir -p "$(dirname "$CONFIG_DIR")"
  rm -rf "$CONFIG_DIR"
  git clone -q "$DOTFILES_REPO" "$CONFIG_DIR"
fi

# --- 5. record the profile (machine-local, gitignored) -------------------------
{
  echo "# Written by install.sh ($PROFILE). Edit, then run \`mise bootstrap\`."
  printf 'env = ['
  sep=""
  for m in $MODULES; do printf '%s"%s"' "$sep" "$m"; sep=", "; done
  echo "]"
} >"$CONFIG_DIR/miserc.toml"

# --- 6. private work layer -------------------------------------------------------
case " $MODULES " in
  *" work "*)
    if [ -d "$CONFIG_DIR/conf.d/work/.git" ]; then
      say "keeping existing work layer at conf.d/work"
    else
      if [ -z "$WORK_REPO" ]; then
        ask "Private work repo URL (git clone URL):"
        WORK_REPO=$REPLY
      fi
      [ -n "$WORK_REPO" ] || die "a work profile needs WORK_REPO"
      # Only gh, pinned by the public config (`mise x` would install everything).
      mise install --yes gh >&2
      GH=$(mise which gh)
      if [ -z "${GITHUB_TOKEN:-}" ] && ! "$GH" auth status >/dev/null 2>&1; then
        say "logging in to GitHub (needed for the private work repo and org tools)"
        has_tty || die "no GitHub login and no terminal; set GITHUB_TOKEN"
        "$GH" auth login </dev/tty >/dev/tty 2>&1
      fi
      say "cloning work layer"
      # gh as the credential helper covers https; ssh URLs and local paths ignore it.
      git -c credential.helper= -c "credential.helper=!'$GH' auth git-credential" \
        clone -q "$WORK_REPO" "$CONFIG_DIR/conf.d/work"
    fi
    ;;
esac

# --- 7. move aside regular files that dotfile links would replace ---------------
# mise re-points symlinks itself but refuses to clobber real files. Its error
# lists the paths, indented, one per line.
attempt=0
until out=$(mise dotfiles apply --yes 2>&1); do
  attempt=$((attempt + 1))
  paths=$(printf '%s\n' "$out" | sed -n 's/^  \(~\/.*\)$/\1/p; s/^  \(\/.*\)$/\1/p')
  if [ "$attempt" -gt 2 ] || [ -z "$paths" ]; then
    printf '%s\n' "$out" >&2
    die "dotfiles could not be applied"
  fi
  printf '%s\n' "$paths" | while IFS= read -r p; do
    # shellcheck disable=SC2088 # matching the literal "~/" mise prints
    case $p in "~/"*) p=$HOME/${p#"~/"} ;; esac
    rel=${p#"$HOME"/}
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    say "backing up $p"
    mv "$p" "$BACKUP_DIR/$rel"
  done
done

# --- 8. converge -------------------------------------------------------------------
say "mise bootstrap (packages, repos, dotfiles, tools)"
mise bootstrap --yes

# --- 9. login shell ------------------------------------------------------------
# Not in the mise config: chsh wants the account password, which headless VMs
# often lack, and a failed phase would stop bootstrap before the tools.
ZSH_PATH=/bin/zsh
current=$( (getent passwd "$USER" 2>/dev/null || dscl . -read "/Users/$USER" UserShell 2>/dev/null) | awk -F'[: ]' '{print $NF}')
if [ "$current" != "$ZSH_PATH" ] && [ -x "$ZSH_PATH" ]; then
  if sudo -n true 2>/dev/null; then
    sudo chsh -s "$ZSH_PATH" "$USER" && say "login shell set to $ZSH_PATH"
  elif has_tty; then
    say "setting login shell to $ZSH_PATH (asks for your password)"
    chsh -s "$ZSH_PATH" </dev/tty || say "chsh failed; run: chsh -s $ZSH_PATH"
  else
    say "run \`chsh -s $ZSH_PATH\` to make zsh your login shell"
  fi
fi

say "done: open a new terminal."
if [ -d "$BACKUP_DIR" ]; then say "replaced files were saved in $BACKUP_DIR"; fi
say "change modules later: edit $CONFIG_DIR/miserc.toml, then \`mise bootstrap\`"
