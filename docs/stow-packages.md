# Stow packages

GNU Stow remains the deployment mechanism. The top-level directories named
in `stow-packages` are the full-profile package set used by `./install`,
`make stow`, `make restow`, and `dots update`.

## Manifest

| Package    | Owns                                                                      |
| ---------- | ------------------------------------------------------------------------- |
| `dots`     | dotfiles control plane: `dots`, doctor, update, keys, versions            |
| `shell`    | core fish profile, Starship, fzf shell UX, generic functions              |
| `cli`      | small CLI defaults/data: atuin, bat, fd, television, Navi cheats          |
| `theme`    | theme command plus fish and Neovim theme adapters                         |
| `terminal` | Ghostty, Kitty, and Alacritty configs                                     |
| `tmux`     | tmux core options, copy mode, status, session helpers                     |
| `nvim`     | LazyVim/kickstart profiles and `knvim`                                    |
| `vcs`      | git, jj, lazygit, VCS fish/tmux/Neovim adapters                           |
| `ai`       | Claude/Codex/OpenCode/pi configs, skills, sandbox wrappers, agent helpers |
| `ssh`      | SSH config, socket/conf.d directories, signing public key                 |
| `mise`     | mise config, fish init, and mise wrapper                                  |
| `yazi`     | Yazi config, fish functions, and keybinding                               |
| `helix`    | Helix editor config                                                       |
| `vm`       | Tart VM helper and its local known-hosts state path                       |
| `zed`      | Zed editor config                                                         |

`stow-packages` is deliberately explicit so repo assets such as `README.md`,
`docs/`, `Brewfile`, `pkgs.arch`, and `mise.toml` cannot be stowed by
accident.

## Ownership rule

A package owns its app config and the adapters that make that app participate
in the profile.

Examples:

- `ai` owns Claude/Codex/OpenCode/pi wrappers, `sb`, nono profiles, and the
  tmux agent fragment.
- `vcs` owns jj's fish wrapper, LazyVim's jj plugin adapter, and tmux VCS
  popup bindings.
- `theme` owns the `theme` command, fish theme environment/completions, and
  LazyVim theme adapter.
- `yazi` owns `y`, `__yazi_cd`, and the `Ctrl-S` fish binding.

This keeps optional packages coherent: if a package is not stowed, its shell,
tmux, and Neovim hooks are absent too.

## Shared extension seams

Several packages intentionally write into the same target directories:

- Fish: `~/.config/fish/conf.d`, `functions`, `completions`
- tmux: `~/.config/tmux/conf.d`
- LazyVim: `~/.config/lazyvim/lua/plugins` and selected `lua/` modules
- User commands: `~/.local/bin`

These directories are stable extension seams. Stow merges their contents so
packages can add integrations without central switchboards in `shell`, `tmux`,
or `nvim`.

## Why `dots` is an orchestrator

The `dots` package intentionally owns commands that coordinate the whole
profile: `dots update`, `dots doctor`, `dots keys`, and related helpers. Those
commands know about the manifest and inspect all packages, but they do not own
individual app integrations.

`dots skills` dispatches to `dots-skills`, which is owned by `ai`. If only the
`dots` package is installed, the command reports that the `ai` package is
required.

## Package managers stay global for now

`Brewfile`, `pkgs.arch`, `pkgs.arch.gui`, and root `mise.toml` remain global
repo assets. They describe the full profile's toolchain rather than a strict
per-package dependency graph. Splitting package-manager inputs per stow package
is intentionally out of scope until the install flow can resolve optional
package dependencies explicitly.

## Migration and stale links

`dots update` removes broken symlinks under common target roots when those
links point inside this repo. This handles links left behind by renamed or
removed packages, including the former `local`, `tools`, and `term` packages
and the deleted `.ideavimrc`.

If a machine was updated without running `dots update`, recover manually with:

```sh
cd ~/dotfiles
while read -r pkg; do
  [ -n "$pkg" ] && stow --dir="$PWD" -t "$HOME" -R "$pkg"
done < stow-packages
find ~/.config ~/.local/bin ~/.local/share ~/.ssh \
  ~/.agents ~/.claude ~/.codex ~/.pi \
  -type l ! -exec test -e {} \; -print
```

Inspect any printed links, then remove the ones that still point inside the
dotfiles checkout and no longer have a target.
