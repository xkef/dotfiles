#!/bin/bash

# first make an update
#echo "update..."
#mac update

# make backupdir
mkdir backup_$(date +%Y_%m_%d)
cd backup_$(date +%Y_%m_%d)

# get important prefs
get_mackup_resources() {
  git clone https://github.com/lra/mackup
  mv mackup/mackup/applications .
  rm -fr mackup 
  for d in applications/*.cfg ; do
    cat $d | sed -r '/^\s*$/d' | \
             sed -r '/^\[/d' | \
             sed -r '/^name/d' | \
             sed -r '/^#/d' >> apps_xkef.txt
  done
  rm -fr applications
  cat apps_xkef.txt | sort > apps_xkef_sorted.txt
}

# mackup
echo "mackup..."
get_mackup_resources
mkdir mackup
rsync -aLkru ~/ \
  --files-from=apps_xkef_sorted.txt \
  --ignore-errors \
  mackup/

# Preferences
echo "prefs..."
mkdir prefs
rsync -aLkru \
  ~/Library/Preferences/ \
  --ignore-errors \
  prefs/

# App Support
echo "appsupport..."
mkdir appsupport
rsync -aLkru  \
  ~/Library/Application\ Support/ \
  --ignore-errors \
  appsupport/

# xkef_mpb with new Brewfile
echo "misc..."
mkdir misc
brew bundle dump && mv Brewfile ~/xkef_mbp 
cd ~/xkef_mbp && git add . && git add * && git commit -m "auto backup"
git push -u origin master
cd ~/backup_$(date +%Y_%m_%d)

# other dotfiles
pip freeze > python3_requirements.txt
cp ~/.history misc
cp ~/.delay_dropbox_start.scpt misc
cp ~/.delay_nordvpn_start.scpt misc
cp ~/.eslintrc misc

