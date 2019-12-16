#!/usr/bin/env bash

mkdir -p frames

for i in {0..157}; do
  ffmpeg -i "${i}.avi" \
    -f image2 "frames/${i}_image-%03d.png"
done
