#!/bin/sh
if [ -d  /Volumes/mnt ]
then
  /usr/bin/rsync -a --progress --delete code /Volumes/mnt/code
  /usr/bin/osascript -e 'display notification "Carry On" with title "rsynced
  ~/code"'
fi
