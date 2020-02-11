export LANG=en_US.UTF-8
export LC_TIME=en_AU.UTF-8

if [ -d "$HOME/.zshenv.d" ]; then
  for EXTENSION_FILE in $(find $HOME/.zshenv.d/ -name '*.zsh'); do
    source "$EXTENSION_FILE"
  done
fi