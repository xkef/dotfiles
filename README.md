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

Deploy installs packages with Homebrew or pacman and links each package under
`modules/` into `$HOME`. A machine gets `core`, `desktop`, and `agents`, and the
Lima VM gets `core` and `agents`. The extras `wezterm`, `helix`, `zed`, and
`kickstart` go in the `packages` list in `~/.local/state/dotter/local.toml`.
`dots apply` deploys again after a change.

## Included tools

| Tool                                                                               | What it does                                               |
| ---------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [Fish](https://fishshell.com)                                                      | Shell with tv pickers and practical defaults               |
| [Starship](https://starship.rs)                                                    | Minimal, cross-shell prompt                                |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org)                   | Editor with the LazyVim distro                             |
| [Ghostty](https://ghostty.org)                                                     | Terminal that runs tmux, themed with the rest              |
| [tmux](https://github.com/tmux/tmux) + [sesh](https://github.com/joshmedeski/sesh) | Multiplexer and sessions, with an agent picker             |
| [WezTerm](https://wezterm.org)                                                     | Extra: terminal and multiplexer, on the tmux keys          |
| `theme`                                                                            | Color themes for terminal, Neovim, Helix, delta, and pi    |
| [television](https://github.com/alexpasmantier/television)                         | Fuzzy finder in the shell and the pickers                  |
| [atuin](https://atuin.sh)                                                          | Searchable local shell history                             |
| [Claude Code](https://claude.com/claude-code), [pi](https://pi.dev)                | AI coding agents, always launched in a nono sandbox        |
| [Jujutsu](https://github.com/jj-vcs/jj)                                            | Git-compatible version control, `jj`, with a simpler model |
| [Lima](https://lima-vm.io)                                                         | Linux development VM with the host's dotfiles setup        |
| [Vale](https://vale.sh)                                                            | Prose linter for markdown, Google style plus AI-tell rules |
| eza, bat, fd, ripgrep, zoxide, yazi, mise                                          | Command-line replacements and workflow tools               |

## Keys

Neovim uses `Space` as leader, and WezTerm and tmux use `Ctrl-Space`. `leader ?`
lists the bindings. `dots theme` switches the colors of every themed tool at
once.

## Agent sandbox

`claude` and `pi` start in a [nono](https://nono.sh) sandbox, whose credential
proxy adds the Claude and GitHub tokens to requests. `agents vm` runs Claude
Code in a [Lima](https://lima-vm.io) VM behind the same proxy. Store the tokens
once:

```sh
claude setup-token  # then store its output:
security add-generic-password -s nono -a claude_code_oauth_token -w
security add-generic-password -s nono -a github-<gh user> -w
# Linux: secret-tool store --label=nono service nono account github-<gh user>
```

## Private files

Private files, such as the git identity, live in `private/home.tar.age`, an
[age](https://age-encryption.org) archive whose key sits in 1Password. A desktop
deploy unpacks it into `$HOME`, next to the configs that include each file.
`mise run encrypt <file>` adds or updates one.

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
