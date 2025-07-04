#!/usr/bin/bash
set -e

n_total=$(wc -l packs.txt | awk '{print $1}')

i=1
for dir in $(find . -mindepth 1 -maxdepth 1 -type d)
do
    echo ''
    echo '---'
    echo ''

    echo "(${i}/${n_total}) ${dir}"

    png_count=$(find "${dir}" -type f -name '*.png' | wc -l)
    echo "  ${png_count}"
    if [ $png_count -eq 0 ]
    then
        gum style --foreground "#ff0000" "  => No PNG files found."
        echo "${dir}" | sed 's/^.\///g' >> packs_new.txt
    else
        gum style --foreground "#55aaff" "  => Pack was synchronized. Skipping..."
    fi

    echo ''
    echo '---'
    echo ''

    ((i++))
done
