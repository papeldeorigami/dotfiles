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
