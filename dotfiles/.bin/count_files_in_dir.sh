#!/bin/bash

# stackoverflow.com/questions/17061948/sorting-strings-with-numbers-in-bash
# and
# /9157138/recursively-counting-files-in-a-linux-directory
# -t separator
# -k key/column
# -g general numeric sort

count_files_per_subdir() {
  for i in $(find . -maxdepth 1 -type d); do
    echo -n $i": "
    (find $i -type f | wc -l)
  done
}

count_files_per_subdir | sort -t : -k 2 -g -r

exit 0
