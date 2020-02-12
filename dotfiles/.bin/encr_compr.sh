#!/bin/sh

tar cf - * |
    xz -9 -c -v - |
    openssl enc -e -aes256 \
        -out $1
