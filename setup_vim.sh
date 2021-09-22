#!/usr/bin/env bash

set -e
# default theme color is: default
export VIM_THEME_COLOR=${VIM_THEME_COLOR:-jummidark}

sudo apt update
sudo apt install vim -y

mkdir -p ~/.vim/colors
wget https://raw.githubusercontent.com/ruanbekker/dotfiles/master/.vim/colors/jummidark.vim
mv jummidark.vim ~/.vim/colors/jummidark.vim

wget https://raw.githubusercontent.com/ruanbekker/dotfiles/master/.vimrc_basic
envsubst < .vimrc_basic > .vimrc

mv .vimrc ~/.vimrc
rm -f .vimrc_basic
