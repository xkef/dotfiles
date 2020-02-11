!#/bin/sh

BASE="/Users/xkef/__dotfiles__"
PACK="/Users/xkef/__dotfiles__/dotfiles/.vim/pack/bundle/opt"
ZSH_MODS="/Users/xkef/__dotfiles__/dotfiles/.zsh/"
npm i -g neovim
pip3 install --upgrade pynvim
gem install neovim

git submodule add https://github.com/wincent/vim-docvim "$PACK"
git submodule add https://github.com/wincent/vim-clipper "$PACK"
git submodule add https://github.com/wincent/vcs-jump "$PACK"
git submodule add https://github.com/wincent/terminus "$PACK"
git submodule add https://github.com/wincent/replay "$PACK"
git submodule add https://github.com/wincent/pinnacle.git "$PACK"
git submodule add https://github.com/wincent/loupe "$PACK"
git submodule add https://github.com/tpope/vim-surround "$PACK"
git submodule add https://github.com/tpope/vim-speeddating "$PACK"
git submodule add https://github.com/tpope/vim-projectionist "$PACK"
git submodule add https://github.com/tpope/vim-pathogen "$PACK"
git submodule add https://github.com/tpope/vim-git "$PACK"
git submodule add https://github.com/tpope/vim-fugitive "$PACK"
git submodule add https://github.com/tpope/vim-dispatch "$PACK"
git submodule add https://github.com/tpope/vim-abolish "$PACK"
git submodule add https://github.com/tomtom/tcomment_vim "$PACK"
git submodule add https://github.com/tommcdo/vim-lion "$PACK"
git submodule add https://github.com/SirVer/ultisnips "$PACK"
git submodule add https://github.com/preservim/nerdtree "$PACK"
git submodule add https://github.com/plasticboy/vim-markdown "$PACK"
git submodule add https://github.com/pangloss/vim-javascript "$PACK"
git submodule add https://github.com/ncm2/float-preview.nvim "$PACK"
git submodule add https://github.com/mxw/vim-jsx "$PACK"
git submodule add https://github.com/mbbill/undotree "$PACK"
git submodule add https://github.com/leafgarland/typescript-vim "$PACK"
git submodule add https://github.com/kana/vim-textobj-user "$PACK"
git submodule add https://github.com/jpalardy/vim-slime "$PACK"
git submodule add https://github.com/glts/vim-textobj-comment "$PACK"
git submodule add https://github.com/elzr/vim-json "$PACK"
git submodule add https://github.com/eagletmt/neco-ghc "$PACK"
git submodule add https://github.com/duganchen/vim-soy "$PACK"
git submodule add https://github.com/chrisbra/vim-zsh "$PACK"

git submodule add https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_MODS"
git submodule add https://github.com/zsh-users/zsh-autosuggestions "$ZSH_MODS"
git submodule add https://github.com/chriskempson/base16-shell/ "$ZSH_MODS"

cd "$BASE" && git submodule update --init --recursive
