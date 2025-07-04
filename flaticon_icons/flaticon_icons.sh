#!/usr/bin/bash
set -e

#
## FUNCTIONS
#

source functions/display.sh

#
## CONFIGURATION VARIABLES
#

FI_AUTHOR_BASE_URL="https://www.flaticon.com/authors"
FI_PACK_BASE_URL="https://www.flaticon.com/packs"

MIRROR_DIR="/data/archive/internetarchive_and_torrents/flaticon"
LOCK="/tmp/mirrors_$(echo ${MIRROR_DIR} | awk -F '/' '{print $NF}').lock"
USERS_DIR="${MIRROR_DIR}/users"

#
## PREPARATION
#

if [ -f "${LOCK}" ]
then
	echo_red "[error] lock at ${LOCK} was created by another process."
	exit 1
fi

touch "${LOCK}"
echo_yellow_pastel "[info] created lock at ${LOCK}"
echo_nl

OLD_SIZE=$(du -sh "${MIRROR_DIR}" | awk '{print $1}')

#
##
#

echo_salmon "[info] If this script is interrupted due to some reason, you can verify which packs were already"
echo_salmon "		downloaded by using the 'fix.sh' script in the"
echo_salmon "		'${PWD}/flaticon_icons' directory."
echo_nl

## Download structure
## - user (specified by user)
## |- style (selectable by user)
##  |- pack (downloads all from a style)
##   |- icons (downloads all from a pack)

if [ ! -d "${USERS_DIR}" ]
then
	mkdir -p "${USERS_DIR}"
	echo "[info] Created the users directory"
else
	echo "[info] Users directory already created. Using it..."
fi

USERNAME=$(gum input --prompt "User > " --cursor.mode "blink")

if [ ! -d "${USERS_DIR}/${USERNAME}" ]
then
	echo "[info] Created the directory for user ${USERNAME}"
	mkdir -p "${USERS_DIR}/${USERNAME}"
else
	echo "[info] Directory for user ${USERNAME} already created. Using it..."
fi

pushd "${USERS_DIR}/${USERNAME}" > /dev/null

echo ""

#
## STYLES
#

if gum confirm "Synchronize styles?"
then
	echo "[${USERNAME}][styles] Synchronizing..."

	if [ ! -d "./styles" ]
	then
		mkdir -p "./styles"
	else
		if [ -f "./styles/styles.txt" ]
		then
			rm "./styles/styles.txt"
			echo "[${USERNAME}][styles][info] Removed old ./styles/styles.txt"
		fi
		if [ -f "./styles/styles_authors.txt" ]
		then
			rm "./styles/styles_authors.txt"
			echo "[${USERNAME}][styles][info] Removed old ./styles/styles_authors.txt"
		fi
		if [ -f "./styles/styles_names.txt" ]
		then
			rm "./styles/styles_names.txt"
			echo "[${USERNAME}][styles][info] Removed old ./styles/styles_names.txt"
		fi
	fi

	i=0
	while true
	do
		((i++)) || true
		
		styles=$(curl --silent "${FI_AUTHOR_BASE_URL}/${USERNAME}/${i}" | pup 'div.author__style__header a.text__general--heading text{}' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]' | tee -a "./styles/styles.txt")
		curl --silent "${FI_AUTHOR_BASE_URL}/${USERNAME}/${i}" | pup 'div.author__style__header a.text__general--heading attr{href}' | awk -F '/' '{print $5}' >> "./styles/styles_authors.txt"
		curl --silent "${FI_AUTHOR_BASE_URL}/${USERNAME}/${i}" | pup 'div.author__style__header a.text__general--heading attr{href}' | awk -F '/' '{print $6}' | sed 's/?.*//g' >> "./styles/styles_names.txt"

		if [ -z "${styles}" ]
		then
			echo "[${USERNAME}][styles] Synchronized $(wc -l ./styles/styles.txt | awk '{print $1}') styles"
			break
		else
			gum style --foreground "#6c6c6c" "${styles}"
		fi
	done
else
	echo "[${USERNAME}][styles] Skipping synchronization..."
fi

echo ""

#
## PACKS
#

STYLES_TO_SYNC=$(gum choose --height 10 --ordered --cursor="> " --show-help --header="Choose styles to synchronize:" --no-limit $(cat "./styles/styles.txt"))

if gum confirm "Synchronize packs?"
then
	for style in $STYLES_TO_SYNC
	do
		if [ ! -d "./styles/${style}" ]
		then
			mkdir -p "./styles/${style}"
		fi

		if [ -f "./styles/${style}/packs.txt" ]
		then
			rm "./styles/${style}/packs.txt"
			echo "[${USERNAME}][styles][${style}][info] Removed old ./styles/${style}/packs.txt"
		fi

		line_number=$(cat "./styles/styles.txt" | grep -Eno "^$style$" | awk -F ':' '{print $1}')
		REAL_USERNAME=$(sed -n "${line_number}"p "./styles/styles_authors.txt")
		REAL_STYLE_NAME=$(sed -n "${line_number}"p "./styles/styles_names.txt")

		if [ ! "$REAL_USERNAME" = "$USERNAME" ]
		then
			echo "[${USERNAME}][styles][${style}][info] Using alternative username: ${REAL_USERNAME}"
		fi
		if [ ! "$REAL_STYLE_NAME" = "$style" ]
		then
			echo "[${USERNAME}][styles][${style}][info] Using alternative style name: ${REAL_STYLE_NAME}"
		fi

		echo "[${USERNAME}][styles][${style}] Synchronizing..."

		i=0
		while true
		do
			((i++)) || true
			
			packs=$(curl --silent "${FI_AUTHOR_BASE_URL}/${REAL_USERNAME}/${REAL_STYLE_NAME}/${i}" | pup 'article.box div.box__inner a attr{href}' | sed 's#https://www.flaticon.com/packs/##g' | tee -a "./styles/${style}/packs.txt")

			if [ -z "${packs}" ]
			then
				echo "[${USERNAME}][styles][${style}] Synchronized $(wc -l ./styles/${style}/packs.txt | awk '{print $1}') packs"
				break
			else
				gum style --foreground "#6c6c6c" "${packs}"
			fi
		done
	done
fi

#
## ICONS
#

if gum confirm "Synchronize icons?"
then
	#for style in $(find "styles/" -mindepth 1 -type d -not -name "." -exec basename {} \;)
	for style in $STYLES_TO_SYNC
	do
		readarray -t packs_array < "./styles/${style}/packs.txt"

		for pack in "${packs_array[@]}"
		do
			echo ""
			echo "[${USERNAME}][styles][${style}][packs][${pack}] Synchronizing..."

			if [ ! -d "./styles/${style}/${pack}" ]
			then
				mkdir -p "./styles/${style}/${pack}"
			fi
			
			if [ -f "./styles/${style}/${pack}/icons.txt" ]
			then
				rm "./styles/${style}/${pack}/icons.txt"
				echo "[${USERNAME}][styles][${style}][packs][${pack}][info] Removed old ./styles/${style}/${pack}/icons.txt"
			fi

			if [ -f "./styles/${style}/${pack}/icons_names.txt" ]
			then
				rm "./styles/${style}/${pack}/icons_names.txt"
				echo "[${USERNAME}][styles][${style}][packs][${pack}][info] Removed old ./styles/${style}/${pack}/icons_names.txt"
			fi

			i=0
			while true
			do
				((i++)) || true

				icons=$(curl --silent "${FI_PACK_BASE_URL}/${pack}/${i}" | pup 'a.link-icon-detail img attr{src}' | tee -a "./styles/${style}/${pack}/icons.txt")
				curl --silent "${FI_PACK_BASE_URL}/${pack}/${i}" | pup 'a.link-icon-detail attr{title}' >> "./styles/${style}/${pack}/icons_names.txt"

				if [ -z "${icons}" ]
				then
					echo "[${USERNAME}][styles][${style}][packs][${pack}] Found $(wc -l ./styles/${style}/${pack}/icons.txt | awk '{print $1}') icons"
					sed -i -e 's#https://cdn-icons-png.flaticon.com/128#https://cdn-icons-png.flaticon.com/512#g' "./styles/${style}/${pack}/icons.txt"
					break
				else
					gum style --foreground "#6c6c6c" "${icons}"
				fi
			done

			echo "[${USERNAME}][styles][${style}][packs][${pack}] Synchronized"
		done
	done
fi

for style in $STYLES_TO_SYNC
do
	readarray -t packs_array < "./styles/${style}/packs.txt"

	for pack in "${packs_array[@]}"
	do
		echo ""
		echo "[${USERNAME}][styles][${style}][packs][${pack}][icons] Downloading..."
		pushd "./styles/${style}/${pack}" > /dev/null
		while true
		do
			# For some reason, when an error occurs and '--retry-connrefused' is set, wget2 exits with status 0.
			#if ! /usr/bin/aria2c -i "icons.txt" --max-concurrent-downloads 10 --optimize-concurrent-downloads true --auto-file-renaming false --allow-overwrite false
			if ! wget2 --progress=bar --robots=off --wait=0 --waitretry=0 --tries 1 --timeout=15 --continue --verbose --input-file "icons.txt"
			then
                if ! gum confirm 'Retry?' --default 'Yes'
                then
                    echo "[${USERNAME}][styles][${style}][packs][${pack}][icons][info] Skipping..."
                    break
                fi
                sleep 2
			else
				break
			fi
		done
		popd > /dev/null
		echo "[${USERNAME}][styles][${style}][packs][${pack}][icons] Downloaded"
	done
done

popd > /dev/null

echo ""
echo "[info] Finished downloading all icons"
echo ""

#
## POST-SYNCHRONIZATION
#

echo_yellow_pastel "[info] removing duplicate files"
find "${MIRROR_DIR}" -name '*.png.*' -exec rm -rf {} \; 2> /dev/null || true

NEW_SIZE=$(du -sh "${MIRROR_DIR}" | awk '{print $1}')

echo_gray ""
echo_gray "=============================="
echo_gray ""

echo_gray "Original Size: ${OLD_SIZE}"
echo_gray "New Size: ${NEW_SIZE}"
echo_gray ""
echo_red "NOTE: this command does not automatically remove old files."

echo_gray ""
echo_gray "=============================="
echo_gray ""

rm "${LOCK}"
echo_yellow_pastel "[info] removed lock at ${LOCK}"

echo_nl
echo_green_pastel "[exit] finished"
echo_nl
