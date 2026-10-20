# dotfiles

[![CI](https://github.com/xkef/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/xkef/dotfiles/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/xkef/dotfiles/badge)](https://scorecard.dev/viewer/?uri=github.com/xkef/dotfiles)

![screenshot](.github/scrot.png)

macOS and Arch Linux dotfiles, deployed with
[Dotter](https://github.com/SuperCuber/dotter).

## Install

```bash
git clone https://github.com/xkef/dotfiles ~/dotfiles
~/dotfiles/setup/deploy
```

Deploy installs packages with Homebrew or pacman and links the configs into
`$HOME`. `dots apply` deploys again after a change.

The configs live in three packages under `modules/`: `core`, `desktop`, and
`agents`. A VM gets `core` and `agents`. The `packages` list in
`~/.local/state/dotter/local.toml` overrides the selection.

## Included tools

| Tool                                                                               | What it does                                               |
| ---------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [Fish](https://fishshell.com)                                                      | Shell with tv pickers and practical defaults               |
| [Starship](https://starship.rs)                                                    | Minimal, cross-shell prompt                                |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org)                   | Editor with the LazyVim distro, kickstart as fallback      |
| [WezTerm](https://wezterm.org)                                                     | Terminal and multiplexer, with an agent picker             |
| [Ghostty](https://ghostty.org)                                                     | Terminal for tmux sessions, themed with the rest           |
| [tmux](https://github.com/tmux/tmux) + [sesh](https://github.com/joshmedeski/sesh) | Multiplexer outside WezTerm, on the same leader key        |
| [tinty](https://github.com/tinted-theming/tinty)                                   | Color themes for the terminal, Neovim, delta, and pi       |
| [television](https://github.com/alexpasmantier/television)                         | Fuzzy finder in the shell and WezTerm pickers              |
| [atuin](https://atuin.sh)                                                          | Searchable shell history with sync                         |
| [Claude Code](https://claude.com/claude-code), [pi](https://pi.dev)                | AI coding agents, always launched in a nono sandbox        |
| [Jujutsu](https://github.com/jj-vcs/jj)                                            | Git-compatible version control, `jj`, with a simpler model |
| [Lima](https://lima-vm.io)                                                         | Linux development VM with the host's dotfiles setup        |
| [Vale](https://vale.sh)                                                            | Prose linter for markdown, Google style plus AI-tell rules |
| eza, bat, fd, ripgrep, zoxide, yazi, mise                                          | Command-line replacements and workflow tools               |

## Keys

Neovim uses `Space` as leader, and WezTerm and tmux use `Ctrl-Space`. `leader ?`
in WezTerm and tmux lists the bindings, and `Space` in Neovim opens the
which-key menu.

`dots theme` switches WezTerm, Ghostty, Neovim, delta, and pi together through
tinty.

## Agent sandbox

`claude` and `pi` start in a [nono](https://nono.dev) sandbox. nono's credential
proxy adds the Claude and GitHub tokens to outgoing requests, so the sandbox
holds only placeholders. `agents vm` runs Claude Code in a
[Lima](https://lima-vm.io) VM on a copy of the repository instead.

## Private files

Private files, such as the git and jj identity, live in an
[age](https://age-encryption.org)-encrypted archive, `private/home.tar.age`.
Encrypt an edited or new file back with:

```sh
mise run encrypt ~/.config/git/identity
```

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
