#!/bin/sh

# converter to .app to have nice icon
# /usr/bin/osascript -e \
#     'display notification "rsync ~/code /mnt" with title "backup finished"'


if [ -d  /Volumes/mnt ]
then
  /usr/bin/rsync -a --progress --delete code /Volumes/mnt/
  open /Applications/Utilities/xkef\ rsync\ backup\ notification.app
fi
