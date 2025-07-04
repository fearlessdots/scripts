#!/usr/bin/bash

echo_nl() {
	echo ""
}

echo_blue() {
	gum style --foreground "#0055ff" "$1"
}

echo_red() {
	gum style --foreground "#ff0000" "$1"
}

echo_gray() {
	gum style --foreground "#6c6c6c" "$1"
}

echo_lightgray() {
	gum style --foreground "#a2a2a2" "$1"
}

echo_yellow_pastel() {
	gum style --foreground "#ffcc79" "$1"
}

echo_green_pastel() {
	gum style --foreground "#b6ff72" "$1"
}

echo_salmon() {
	gum style --foreground "#ff7c73" "$1"
}

echo_red_pastel() {
	gum style --foreground "#ff557f" "$1"
}

echo_orange_pastel() {
	gum style --foreground "#ff9940" "$1"
}
