# dotfiles


```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/raadk/dotfiles.git
cd dotfiles

# Take what you need
cp .tmux.conf ~/.tmux.conf
cp .vimrc ~/.vimrc

# Fom vim
# :PluginInstall

# For tmux
tmux source ~/.tmux.conf
# prefix + I
```
