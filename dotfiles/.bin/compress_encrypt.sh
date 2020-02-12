#!/bin/sh

# 1. 'tar' saves many files together into a single tape or
#    disk archive.
#
# 2. 'xz' is a general-purpose data compression tool,
#     we use high compression rate and verbose output.
#
# 3. 'openssl is a cryptography toolkit, we use strong, symmetric
#     aes256 encryption.
#
# 4. upload to file.io using curl, expiry 24h / 1 download

# output destination
set -e

OUTPUT_FILE="$1"'.encrypted.xz'

echo '-> compress (xz) and encrypt (aes256): ' $OUTPUT_FILE

# compression: xz for better compression ratio
# encryption: openssl with aes256 (basically uncrackable using good password)
tar cf - "$1" |
    xz -9 -c -v - |
    openssl enc -e -aes256 \
        -out "$OUTPUT_FILE"

exit 0
