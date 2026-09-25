# dotfiles

[![CI](https://github.com/xkef/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/xkef/dotfiles/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/xkef/dotfiles/badge)](https://scorecard.dev/viewer/?uri=github.com/xkef/dotfiles)

![screenshot](.github/scrot.png)

macOS and Arch Linux dotfiles, managed with [chezmoi](https://www.chezmoi.io).

## Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply xkef/dotfiles
```

This installs packages with Homebrew or pacman, writes configs into `$HOME`, and
sets fish as the default shell.

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
| [Claude Code](https://claude.ai/), Codex, pi                     | AI coding agents, always launched in a nono sandbox        |
| [Jujutsu](https://github.com/jj-vcs/jj)                          | Git-compatible version control, `jj`, with a simpler model |
| [Lima](https://lima-vm.io)                                       | Linux development VM with the host's chezmoi setup         |
| [Vale](https://vale.sh)                                          | Prose linter for markdown, Google style plus AI-tell rules |
| eza, bat, fd, ripgrep, zoxide, yazi, mise                        | Command-line replacements and workflow tools               |

## Keys

Neovim uses `Space` as leader and WezTerm uses `Ctrl-Space`. Change both in
[`home/.chezmoidata/keys.toml`](home/.chezmoidata/keys.toml). `leader ?` in
either lists the bindings.

`dots theme` switches WezTerm, Neovim, delta, and pi together through tinty.

## Make it yours

Edit [`home/.chezmoidata/identity.toml`](home/.chezmoidata/identity.toml). Git,
jj, and SSH read your name, email, and signing key from it. When the 1Password
`op` command exists, git and jj read name and email from 1Password.

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
