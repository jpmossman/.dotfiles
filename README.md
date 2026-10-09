# dotfiles

My machine setup (shell, git, editor, terminal, CLI tools, language runtimes,
host packages and dotfile links) as one [mise](https://mise.jdx.dev) configuration.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/jpmossman/dotfiles/main/install.sh | sh
```

It asks for a profile. To skip the prompt, pass one: `… | sh -s -- work-headless`.

| Profile | For | Modules |
|---|---|---|
| `personal` | my own machines | gui, personal, embedded |
| `work` | work laptop/desktop | gui, work, embedded |
| `work-headless` | throwaway VMs, SSH boxes | work, embedded |

`install.sh` does this:

1. installs git/curl if missing (Xcode CLT on macOS, apt on Linux) and installs mise
2. clones this repo to `~/.config/mise`
3. writes the profile's modules to `~/.config/mise/miserc.toml` (machine-local, untracked)
4. for work profiles, logs in with `gh` (or uses `$GITHUB_TOKEN`) and clones the private work
   layer into `conf.d/work/`; its URL comes from `$WORK_REPO` or a prompt
5. moves any real files that a dotfile link would replace to `~/.dotfiles-backup/<timestamp>/`
6. runs `mise bootstrap`, which applies, in order: host packages, git repos, dotfiles, tools,
   login shell

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
| add a tool | add it to the matching `conf.d/*/mise.toml` (`mise use -g` writes to `config.toml`) |
| upgrade pins | `mise outdated`, `mise upgrade --bump` |
| find unmanaged installs | `mise run dot:drift` |

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
