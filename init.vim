" =============================================================================
" -- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- CO
" =============================================================================
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
    echo 'INSTALLING: vim-plug'
    !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.local/share/nvim/plugged')
Plug 'dracula/vim',{'as':'dracula'}   " Syntax coloring theme
Plug 'blueyed/vim-diminactive'
Plug 'vim-airline/vim-airline'        " Status line
Plug 'vim-airline/vim-airline-themes' " Status line themes
Plug 'ryanoasis/vim-devicons'         " Gyphs for vim-airline
Plug 'junegunn/limelight.vim'         " Highlight active paragraph
Plug 'junegunn/rainbow_parentheses.vim'
Plug 'ervandew/supertab'
Plug 'jiangmiao/auto-pairs'
Plug 'brooth/far.vim'
Plug 'roxma/nvim-completion-manager'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-surround'
Plug 'majutsushi/tagbar'
Plug 'airblade/vim-gitgutter'
Plug 'philip-karlsson/bolt.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'cyansprite/Extract'            " NEOVIM:
call plug#end()
" =============================================================================
" -- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- CO
" =============================================================================
set nocompatible            " Disable compatibility to old-time vi
set showmatch               " Show matching brackets.
set nowrap
set number                  " add line numbers
set hlsearch                " highlight search results
set ignorecase              " Do case insensitive matching
set smartcase
set tabstop=4               " number of columns occupied by a tab character
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set shiftwidth=4            " width for autoindents
set expandtab               " converts tabs to white space
set mouse=v                 " middle-click paste with mouse
set autoindent              " indent a new line the same amount as the line just typed
set wildmode=longest,list   " get bash-like tab completions
set cc=80                   " set an 80 column border for good coding style
set invspell                " set spell checker
set autochdir
syntax enable
color dracula
"""":highlight Pmenu ctermbg=238 gui=bold
set termguicolors
" =============================================================================
" -- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBIN
" =============================================================================
let mapleader = "§"
nnoremap <leader>s  :set invspell!<CR> " toggle spelling
nnoremap <leader>h  :set hlsearch!<CR> " toggle search highlights
nnoremap <leader>ss :w !sudo tee %     " open with sudo
nnoremap <Leader>w  /\s\+$<CR>         " search trailing spaces
nnoremap <Leader>v  :Vexplore<CR>
nnoremap <F1>       :vertical help<Space>
