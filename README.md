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

This installs packages with Homebrew or pacman, links configs into `$HOME`, and
sets fish as the default shell. `dots apply` deploys again after a change.

## Included tools

| Tool                                                             | What it does                                               |
| ---------------------------------------------------------------- | ---------------------------------------------------------- |
| [Fish](https://fishshell.com)                                    | Shell with tv pickers and practical defaults               |
| [Starship](https://starship.rs)                                  | Minimal, cross-shell prompt                                |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org) | Editor with the LazyVim distro, kickstart as fallback      |
| [WezTerm](https://wezterm.org)                                   | Terminal and multiplexer, with an agent picker             |
| [tinty](https://github.com/tinted-theming/tinty)                 | Color themes for the terminal, Neovim, delta, and pi       |
| [television](https://github.com/alexpasmantier/television)       | Fuzzy finder in the shell and WezTerm pickers              |
| [atuin](https://atuin.sh)                                        | Searchable shell history with sync                         |
| [Claude Code](https://claude.ai/), pi                            | AI coding agents, always launched in a nono sandbox        |
| [Jujutsu](https://github.com/jj-vcs/jj)                          | Git-compatible version control, `jj`, with a simpler model |
| [Lima](https://lima-vm.io)                                       | Linux development VM with the host's dotfiles setup        |
| [Vale](https://vale.sh)                                          | Prose linter for markdown, Google style plus AI-tell rules |
| eza, bat, fd, ripgrep, zoxide, yazi, mise                        | Command-line replacements and workflow tools               |

## Keys

Neovim uses `Space` as leader and WezTerm uses `Ctrl-Space`. `leader ?` in
either lists the bindings.

`dots theme` switches WezTerm, Neovim, delta, and pi together through tinty.

## Make it yours

Replace the name, email, and signing key in
[`home/vcs/git/config`](home/vcs/git/config),
[`home/vcs/jj/config.toml`](home/vcs/jj/config.toml), and
[`home/security/ssh/github.pub`](home/security/ssh/github.pub). When the
1Password `op` command exists, [`setup/identity/render`](setup/identity/render)
reads name and email from 1Password instead.

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
