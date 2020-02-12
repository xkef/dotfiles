token='Authorization: Bearer ...'
curl 'https://graph.microsoft.com/v1.0/me/drive' \
    -H 'sec-ch-ua: Google Chrome 77' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Origin: http://localhost:30662' \
    -H 'Referer: http://localhost:30662/' \
    -H 'Sec-Fetch-Dest: empty' \
    -H $token \
    --compressed |
    jq
