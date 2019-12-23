#/bin/bash
current_dir=$(pwd)
BASEDIR=$(dirname $0)
if [ $BASEDIR = '.' ]; then
	BASEDIR="$current_dir"
fi
[ ! -d ~/.byobu ] || mv ~/.byobu ~/.byobu.old || rm -rf ~/.byobu
ln -s $BASEDIR/.byobu ~/.byobu
[ ! -d ~/.vim ] || mv ~/.vim ~/.vim.old || rm -rf ~/.vim
ln -s $BASEDIR/.vim ~/.vim
[ ! -f ~/.vimrc ] || mv ~/.vimrc ~/.vimrc.old || rm -rf ~/.vimrc
ln -s $BASEDIR/.vim/.vimrc ~/.vimrc
[ ! -f ~/.ctags ] || mv ~/.ctags ~/.ctags.old || rm -rf ~/.ctags
ln -s $BASEDIR/.ctags ~/.ctags
VSCODEDIR=~/.config/Code/User
mkdir -p $VSCODEDIR
[ ! -f $VSCODEDIR/keybindings.json ] || mv $VSCODEDIR/keybindings.json $VSCODEDIR/keybindings.json.old || rm -f $VSCODEDIR/keybindings.json
[ ! -f $VSCODEDIR/settings.json ] || mv $VSCODEDIR/settings.json $VSCODEDIR/settings.json.old || rm -f $VSCODEDIR/settings.json
ln -s $BASEDIR/vscode/keybindings.json $VSCODEDIR/keybindings.json
ln -s $BASEDIR/vscode/settings.json $VSCODEDIR/settings.json
