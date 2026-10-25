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

The configs live in packages under `modules/`. A machine gets `core`, `desktop`,
and `agents`, and a VM gets `core` and `agents`. The extras `wezterm`, `helix`,
`zed`, and `kickstart` install only when selected. The `packages` list in
`~/.local/state/dotter/local.toml` sets the selection:

```toml
packages = ["core", "desktop", "agents", "wezterm"]
```

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
in WezTerm and tmux lists the bindings, and `Space` in Neovim opens the
which-key menu.

`dots theme` switches Ghostty, WezTerm, Neovim, Helix, delta, and pi together.
It offers Catppuccin, Tokyo Night, Rosé Pine, and Kanagawa, each a palette file
in `modules/core/.config/theme/palettes`.

## Agent sandbox

`claude` and `pi` start in a [nono](https://nono.sh) sandbox. nono's credential
proxy adds the Claude and GitHub tokens to outgoing requests, so the sandbox
holds only placeholders. `agents vm` runs Claude Code in a
[Lima](https://lima-vm.io) VM on a copy of the repository instead, behind the
same proxy.

## Private files

Private files, such as the git and jj identity, live in an
[age](https://age-encryption.org)-encrypted archive, `private/home.tar.age`,
which the deploy unpacks into `$HOME`. The archive only adds files. It skips a
path that a package links, so each private file sits where a tracked config
includes it:

| Tool    | Private file                               | Holds                                         |
| ------- | ------------------------------------------ | --------------------------------------------- |
| git     | `~/.config/git/identity`, `config.local`   | identity, signing, and accounts by directory  |
| jj      | `~/.config/jj/conf.d/*.toml`               | identity, signing, and accounts by repository |
| ssh     | `~/.ssh/conf.d/*.conf`                     | hosts                                         |
| fish    | `~/.config/fish/local.fish`                | anything                                      |
| tmux    | `~/.config/tmux/local.conf`                | anything                                      |
| Ghostty | `~/.config/ghostty/local`                  | anything                                      |
| WezTerm | `~/.config/wezterm/local.lua`              | a function that changes the config            |
| Neovim  | `~/.config/lazyvim/lua/plugins/local.lua`  | a lazy.nvim spec                              |
| mise    | `~/.config/mise/conf.d/*.toml`             | environment by directory                      |
| deploy  | `~/.config/dotfiles/post-deploy.d/*`       | setup that runs after each deploy             |

gh keeps its logins in the system keychain and writes its own `config.yml`, so
it has no private file. One mise file routes gh, git, and jj to an account by
directory, because each of them reads `GH_TOKEN`:

```toml
# ~/.config/mise/conf.d/accounts.toml
[env]
GH_TOKEN = '''
{%- if "/Users/me/work/" in cwd ~ "/" -%}
  {{- exec(command="gh auth token --user me-work",
      cache_key="gh-me-work", cache_duration="1d") -}}
{%- else -%}
  {{- exec(command="gh auth token --user me",
      cache_key="gh-me", cache_duration="1d") -}}
{%- endif -%}
'''
```

Encrypt an edited or new file back with:

```sh
mise run encrypt ~/.config/git/identity
```

## Credits

Inspired by [wincent/wincent](https://github.com/wincent/wincent), with
borrowings from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
[ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles), and
[LazyVim](https://github.com/LazyVim/LazyVim).
