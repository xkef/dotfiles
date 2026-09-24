# Command-line tools for every machine, from nixpkgs. GUI apps and the few
# tools nixpkgs lags on come from Homebrew (nix/darwin.nix) or pacman
# (nix/arch-packages.txt). mise installs language toolchains
# (home/.config/mise/config.toml).
pkgs:
with pkgs;
[
  git # version control
  curl # URL data transfer
  less # pager (used as $PAGER)
  gh # GitHub from the command line
  jq # JSON processor
  age # simple file encryption
  starship # cross-shell prompt
  atuin # shell history search/sync
  fzf # fuzzy finder
  zoxide # smarter cd with frecency
  helix # modal text editor (Rust)
  neovim # text editor
  tree-sitter # parser generator CLI (nvim-treesitter build)
  presenterm # markdown-driven terminal slides
  eza # modern ls replacement
  bat # cat with syntax highlighting
  fd # modern find replacement
  ripgrep # fast recursive grep
  xh # fast HTTP client (HTTPie-compatible)
  hurl # HTTP request testing with plain text files
  sd # intuitive find-and-replace (sed alt)
  scooter # interactive find-and-replace TUI
  dust # disk usage viewer (du alt)
  duf # disk free viewer (df alt)
  procs # modern ps replacement
  ouch # compress/decompress archives
  delta # syntax-highlighting diff pager
  difftastic # structural diff tool
  lazygit # terminal UI for git
  jujutsu # Jujutsu version control
  jjui # terminal UI for jj
  onefetch # git repo summary in terminal
  mise # dev tool version manager
  jdt-language-server # Java language server
  ccusage # Claude Code usage analyzer
  devcontainer # dev container CLI
  podman # rootless container engine
  lazydocker # terminal UI for Docker/Podman
  fx # terminal JSON viewer
  yazi # terminal file manager
  glow # terminal markdown renderer
  vale # prose linter for markdown
  tinty # color scheme switcher
  tokei # code statistics by language
  tealdeer # fast tldr client
  htop # interactive process viewer
  hyperfine # command-line benchmarking
  bandwhich # per-process bandwidth monitor
  xdg-ninja # audit XDG base-dir compliance
]
++ lib.optionals stdenv.isDarwin [
  lima # Linux dev VMs (home/.config/lima/dev.yaml)
]
++ lib.optionals stdenv.isLinux [
  trash-cli # move files to trash instead of rm (macOS ships `trash`)
]
