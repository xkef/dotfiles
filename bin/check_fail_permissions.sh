#!/bin/sh
find / -uid 0 -type f -perm -333 2>/dev/null -exec ls -l {} \;
