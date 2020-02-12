#!/usr/bin/env bash

# params
URL="https://www.ethz.ch/content/specialinterest/infk/information-security/information-security-group/en/education/ss2019/infsec/course_material_secured.html"
COOKIE="Cookie:_shibsession_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# prepare tmp fs
cd /tmp; mkdir infosec; cd infosec

# fetch links of pdfs from html index
#   1. grab html behind auth. wall
#   2. filter out urls to pdf
#   3. finalize list with sed
curl $URL -H $COOKIE --compressed   \
| grep -Eo '"https.*.pdf"'          \
| sed 's/"//g'                      \
> links_to_courseware_pdfs.log

# download courseware in parallel for speed with wget
cat links_to_courseware_pdfs.log | parallel --gnu "wget --header $COOKIE {}"
