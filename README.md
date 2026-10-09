# dotfiles

My machine setup (shell, git, editor, terminal, CLI tools, language runtimes,
host packages and dotfile links) as one [mise](https://mise.jdx.dev) configuration.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/jpmossman/.dotfiles/main/install.sh | sh
```

It asks for a profile. To skip the prompt, pass one: `… | sh -s -- work-headless`.

| Profile | For | Modules |
|---|---|---|
| `personal` | my own machines | gui, personal, embedded |
| `work` | work laptop/desktop | gui, work, embedded |
| `work-headless` | throwaway VMs, SSH boxes | work, embedded |

`install.sh` does this:

1. installs git/curl if missing (Xcode CLT on macOS, apt on Linux) and installs mise
2. clones this repo to `~/.config/mise`, and links `~/.dotfiles` to it if that path is free
3. writes the profile's modules to `~/.config/mise/miserc.toml` (machine-local, untracked)
4. for work profiles, logs in with `gh` (or uses `$GITHUB_TOKEN`) and clones the private work
   layer into `conf.d/work/`; its URL comes from `$WORK_REPO` or a prompt
5. moves any real files that a dotfile link would replace to `~/.dotfiles-backup/<timestamp>/`
6. runs `mise bootstrap`, which applies, in order: host packages, git repos, dotfiles, tools
7. sets zsh as the login shell (via sudo if passwordless, otherwise `chsh` prompts)

Re-running it is safe.

## Layout

```
config.toml             settings (GitHub token lookup, cargo binstall, uv)
install.sh
conf.d/<concern>/       one folder per concern, stow-package style:
  mise.toml               always loaded: its [tools], [bootstrap.packages], [dotfiles], [env]
  mise.<module>.toml      loaded only when <module> is in miserc.toml
  files/…                 dotfile sources, laid out as they appear under ~
conf.d/
  core/ cli/ rust/ go/ python/ nvim/ git/ shell/ terminal/ host-packages/ meta/
  embedded/             cmake, ninja, conan, clang-format, ARM GCC, LLVM, probe-rs
  personal/             personal git identity
  work/                 (not in this repo) private layer, cloned on work machines
test/orb/               runs install.sh per profile in isolated OrbStack VMs
```

Modules are mise [config environments](https://mise.jdx.dev/configuration/environments.html):
`miserc.toml` lists them (`env = ["gui", "personal", "embedded"]`), and mise then loads every
matching `mise.<module>.toml`. Git identity works the same way: the shared git config includes
`~/.config/git/identity`, and the `personal` or `work` module provides that file.

## Day to day

| Want to… | Run |
|---|---|
| preview changes | `mise bootstrap --dry-run` (`bootstrap plan` skips dotfile conflicts) |
| apply everything | `mise bootstrap` |
| pull updates | `git -C ~/.config/mise pull && mise bootstrap` |
| switch modules | edit `~/.config/mise/miserc.toml`, then `mise bootstrap`; `mise bootstrap unapply <module>` removes a dropped module's files |
| add software | see [Adding software](#adding-software) |
| upgrade pins | `mise outdated`, `mise upgrade --bump` |
| find unmanaged installs | `mise run dot:drift` |

## Adding software

Install through mise and point it at the right file. That writes the change
into this checkout (`~/.config/mise`, also reachable as `~/.dotfiles`), so it
shows up in `git status`.

**CLI tools and runtimes:**

```sh
mise use --path ~/.config/mise/conf.d/cli/mise.toml hyperfine@latest
```

- `@latest` resolves to the current version and pins it.
- Pick the folder that fits: `cli/`, `rust/`, `go/`, `python/`, …
- For something only one profile should get, use that module's file, e.g.
  `conf.d/embedded/mise.embedded.toml`.
- `mise use -g` also works, but it writes to the top-level `config.toml`; move the line later.
- **Watch out:** plain `mise use foo` (no `-g`/`--path`) writes to the project `mise.toml` in
  whatever directory you're in.

**Apps, casks, fonts, system libraries:**

```sh
mise bootstrap packages use --path ~/.config/mise/conf.d/host-packages/mise.toml brew:jq
mise bootstrap packages use --path ~/.config/mise/conf.d/host-packages/mise.gui.toml brew-cask:obsidian
```

- That writes the entry and installs it in one step.
- Add `os = "macos"` (or `"linux"`) by hand to match the neighbouring entries.
- Prefer this over running `brew` yourself: machines set up from this repo get brew packages
  from mise and may not have `brew` at all.

**Installed something by hand anyway** (`brew install`, `cargo install`, `uv tool install`)?

- `mise run dot:drift` lists everything installed that the config doesn't declare. Add each one
  with the commands above.
- `mise bootstrap packages import --manager brew --dry-run` prints ready-to-paste brew entries.

**Then record it:**

```sh
cd ~/.dotfiles && git add -A && git commit -m "add hyperfine" && git push
```

Other machines pick it up with `git -C ~/.config/mise pull && mise bootstrap`. Work-only tools
belong in the private layer instead: edit `~/.config/mise/conf.d/work/mise.work.toml`, then
commit and push from that directory (it's its own repo).

## Testing changes

```sh
test/orb/create.sh personal      # isolated VM; only the repo(s) are mounted
git commit …                     # the VM clones, so only committed changes count
test/orb/run.sh personal         # curl|sh-style install, checks, re-run; log in .sandbox/logs/
test/orb/destroy.sh personal
```

The work profiles also mount `../.dotfiles-work`, the private layer's checkout.

**Don't wrap these in `mise run` on your own machine.** `mise run` and `mise x` first install
every missing tool in the config.

## Known limits

- `lockfile = true` is left out of the global config on purpose: in mise 2026.9 and 2026.10 it
  breaks `pipx:` installs.
- Tools with no linux-arm64 builds are gated with `os = ["macos", "linux/x64"]`: neovim 0.9.1,
  grex, mask, onefetch.
