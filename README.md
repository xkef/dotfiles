# dotfiles

[![CI](https://github.com/xkef/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/xkef/dotfiles/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/xkef/dotfiles/badge)](https://scorecard.dev/viewer/?uri=github.com/xkef/dotfiles)

![screenshot](.github/scrot.png)

macOS and Arch Linux dotfiles, managed with [Nix](https://nixos.org):
[nix-darwin](https://github.com/nix-darwin/nix-darwin) on macOS and
[home-manager](https://github.com/nix-community/home-manager) everywhere.

## Install

```bash
git clone https://github.com/xkef/dotfiles ~/dotfiles && ~/dotfiles/bootstrap
```

This installs Nix and applies the flake. Command-line tools come from
nixpkgs, GUI apps from Homebrew casks or pacman, and language toolchains from
mise. On macOS, nix-darwin also applies the system settings. Later changes
apply with `dots switch`.

## Layout

| Path                                   | Holds                                                      |
| -------------------------------------- | ---------------------------------------------------------- |
| [`home/`](home)                        | Files that mirror `$HOME`, linked into place, live on edit |
| [`nix/settings.nix`](nix/settings.nix) | Username, checkout path, and git identity                  |
| [`nix/packages.nix`](nix/packages.nix) | Command-line tools for every machine                       |
| [`nix/darwin.nix`](nix/darwin.nix)     | macOS system settings, login shell, and Homebrew casks     |
| [`nix/home.nix`](nix/home.nix)         | The links, generated files, and activation steps           |
| [`nix/agents.toml`](nix/agents.toml)   | AI agent registry: launchers, sandbox profiles, and rules  |

## Included tools

| Tool                                                             | What it does                                               |
| ---------------------------------------------------------------- | ---------------------------------------------------------- |
| [Fish](https://fishshell.com)                                    | Shell with television pickers and practical defaults       |
| [Starship](https://starship.rs)                                  | Minimal, cross-shell prompt                                |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org) | Editor with the LazyVim distro                             |
| [WezTerm](https://wezterm.org)                                   | Terminal and multiplexer, with an agent-aware status line  |
| [television](https://github.com/alexpasmantier/television)       | Fuzzy finder in the shell and Neovim, one channel per task |
| [atuin](https://atuin.sh)                                        | Searchable shell history with sync                         |
| [Claude Code](https://claude.ai/)                                | AI coding agent, always launched in a nono sandbox         |
| [Jujutsu](https://github.com/jj-vcs/jj)                          | Git-compatible version control, `jj`, with a simpler model |
| [Lima](https://lima-vm.io)                                       | Linux development VM with the host's home-manager setup    |
| [Vale](https://vale.sh)                                          | Prose linter for markdown, Google style plus AI-tell rules |
| eza, bat, fd, ripgrep, zoxide, yazi, mise                        | Command-line replacements and workflow tools               |

## Keys

Neovim uses `Space` as leader and WezTerm uses `Ctrl-Space`. Change them in
[`home/.config/lazyvim/init.lua`](home/.config/lazyvim/init.lua) and
[`home/.config/wezterm/keys.lua`](home/.config/wezterm/keys.lua). `leader ?`
in either lists the bindings.

`theme` switches WezTerm, Neovim, and delta together through
[tinty](https://github.com/tinted-theming/tinty).

## Make it yours

Edit [`nix/settings.nix`](nix/settings.nix). Git, jj, and SSH read your name,
email, and signing key from it. When the 1Password `op` command can read the
vault, git and jj read name and email from 1Password.

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
