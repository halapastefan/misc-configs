#!/bin/zsh

languages=`echo "java javascript typescript" | tr ' ' '\n'`
core_utils=`echo "aws awk curl sed jq" | tr ' ' '\n'`

selected=`printf "${core_utils}\n${languages}" | fzf`

if echo "$languages" | grep -qx "$selected"; then
    echo "You selected a language: $selected"
elif echo "$core_utils" | grep -qx "$selected"; then
    curl -s "https://cht.sh/$selected" 
fi