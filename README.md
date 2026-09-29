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
| [tmux](https://github.com/tmux/tmux) + [sesh](https://github.com/joshmedeski/sesh) | Multiplexer outside WezTerm, on the same keys              |
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
in any of them lists the bindings.

`dots theme` switches WezTerm, Ghostty, Neovim, delta, and pi together through
tinty.

## Agent sandbox

`claude` and `pi` always start in a [nono](https://nono.dev) sandbox. The
default profile limits writes to the working directory, the agent's own state,
and toolchain directories, and keeps the credentials needed to commit and push.
`sb --strict claude` drops those credentials for untrusted repositories. The
profiles live in `modules/agents/.config/nono/profiles/`.

`agents vm`, or `lima-agent`, runs Claude Code in a Lima VM, with `~/code` and
`~/work` mounted from the host. `agents skills` refreshes the shared agent
skills, and `agents trace` reports failed tool calls in Claude Code sessions.

## Make it yours

Private files, such as the git and jj identity, live in one archive encrypted
with [age](https://age-encryption.org), `private/home.tar.age`, which mirrors
`$HOME` and hides the file names. Deploy decrypts it into `~` with the key in
1Password at `op://Dev/dotfiles-age-key/password`, and skips a file edited
since. After editing one, or to add one, encrypt it back:

```sh
mise run encrypt ~/.config/git/identity
```

The git config includes `~/.config/git/identity`, and jj reads
`~/.config/jj/conf.d/identity.toml`. Both set the default account and one
account per directory.

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
