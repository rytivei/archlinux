set nocompatible
set encoding=utf8
set termencoding=utf-8
set nowrap
set number
set hlsearch
set ignorecase
set smartcase
set tabstop=4
set shiftwidth=4
set autoindent
syntax enable
let mapleader = "§"
let g:bufferline_echo = 0
let g:netrw_chgwin=1

augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" =============================================================================
" -- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBIN
" =============================================================================

"---- [FUNCTION KEY MAPPINGS] ----"

noremap <silent> <F1> :help<CR>
noremap <silent> <F2> :Lexplore<CR>
let g:lt_quickfix_list_toggle_map = '<F3>'
let g:lt_location_list_toggle_map = '<F4>'

"---- [NORMAL KEY MAPPINGS] ----"

nnoremap <Tab>           :bnext<CR>
nnoremap <Leader><Tab>   :bprevious<CR>
nnoremap <Leader><Right> <C-w>l
nnoremap <Leader><Up>    <C-w>k
nnoremap <Leader><Down>  <C-w>j
nnoremap <Leader><Left>  <C-w>h
nnoremap <Leader>+       :vertical resize +5<CR>
nnoremap <Leader>-       :vertical resize -5<CR>
nnoremap <Leader>n       :vertical split<CR>
nnoremap <Leader>ne      :vertical split new<CR>
nnoremap <Leader>r       :q<CR>
nnoremap <Leader>rr      :bdelete<CR>
nnoremap <Leader>s       :w !sudo tee %

"""" search trailing spaces
nnoremap <Leader>w       /\s\+$<CR>

"""" comment/ uncomment in V-LINE mode
vmap <S-c>               :s/^/#/<CR> :noh<CR>
vmap <S-c><S-c>          :s/^#//<CR> :noh<CR>

" =============================================================================
" -- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VU
" =============================================================================

let iCanHazVundle=1
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
    echo "Installing Vundle.."
    echo ""
    silent !mkdir -p ~/.vim/bundle
    silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
    let iCanHazVundle=0
endif
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'bling/vim-airline'
""""Bundle 'fholgado/minibufexpl.vim'
Bundle 'bling/vim-bufferline'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-surround'
Bundle 'vim-scripts/a.vim'
Bundle 'kien/ctrlp.vim'
Bundle 'darvelo/vim-systemd'
Bundle 'scrooloose/syntastic'
Bundle 'valloric/listtoggle'
if iCanHazVundle == 0
    echo "Installing Bundles, please ignore key map error messages"
    echo ""
    :BundleInstall
endif

" =============================================================================
" -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P --
" =============================================================================

let g:ctrlp_map = '<F6>'
let g:ctrlp_cmd = 'call ToggleCtrlP()'

let g:ctrlp_is_open = 0
function! ToggleCtrlP()
    if g:ctrlp_is_open
        let g:ctrlp_is_open = 0
        close
    else
        let g:ctrlp_is_open = 1
        CtrlPMixed
    endif
endfunction

" =============================================================================
" -- STATUS LINE ---- STATUS LINE ---- STATUS LINE ---- STATUS LINE ---- STATUS
" =============================================================================

set laststatus=2
set t_Co=256

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

let g:airline_theme='murmur'
let g:airline_powerline_fonts=1

"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
"let g:airline_symbols.linenr = '␊'
"let g:airline_symbols.linenr = '␤'
"let g:airline_symbols.linenr = '¶'
"let g:airline_symbols.branch = '⎇'
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.paste = 'Þ'
"let g:airline_symbols.paste = '∥'
"let g:airline_symbols.whitespace = 'Ξ'
