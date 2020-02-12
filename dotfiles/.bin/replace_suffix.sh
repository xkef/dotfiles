#!/bin/sh

replace_suffix() {
    for file in *.$1; do
        echo $file $(basename $file .$1).$2
        mv $file '$(basename $file .$1).$2'
    done
}
