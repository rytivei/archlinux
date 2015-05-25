" =============================================================================
" -- SET LANGUAGE (UI/MENUS) ---- SET LANGUAGE (UI/MENUS) ---- SET LANGUAGE (UI
" =============================================================================

if has('win32')
    if has('gui_running')
        set langmenu=en
        set guifont=Lucida_Console:h9
	language messages EN	
    endif
endif

" =============================================================================
" -- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VUNDLE ---- VU
" =============================================================================

set nocompatible
filetype off

let iCanHazVundle=1

if has ('win32')
    let vundle_readme=expand('$HOME/vimfiles/bundle/vundle/README.md')
    if !filereadable(vundle_readme)
        :echom "Open a command prompt (cmd.exe)"
        :echom "cd %USERPROFILE%"
        :echom "git clone https://github.com/gmarik/vundle vimfiles/bundle/vundle"
        :echom "--"
        :echom "Manually install Bundles with :BundleInstall after restart."
        :quit
    endif
else
    let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
    if !filereadable(vundle_readme)
        silent !mkdir -p ~/.vim/bundle
        silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
        let iCanHazVundle=0
    endif
endif

if has ('win32')    
    set rtp+=$HOME/vimfiles/bundle/vundle/
    let path='$HOME/vimfiles/bundle'
else
    set rtp+=~/.vim/bundle/vundle/
    let path='~/.vim/bundle'
endif

call vundle#begin(path)

Bundle 'gmarik/vundle'
Bundle 'bling/vim-airline'
Bundle 'kien/ctrlp.vim'

""""Bundle 'bling/vim-bufferline'
""""Bundle 'tpope/vim-fugitive'
""""Bundle 'tpope/vim-surround'
""""Bundle 'vim-scripts/a.vim'
""""Bundle 'darvelo/vim-systemd'
""""Bundle 'scrooloose/syntastic'
""""Bundle 'valloric/listtoggle'

call vundle#end()
filetype plugin indent on

if iCanHazVundle == 0
    :BundleInstall
endif

" =============================================================================
" -- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- COMMON ---- CO
" =============================================================================

set encoding=utf8
set termencoding=utf-8
set nowrap
set number
set hlsearch
set ignorecase
set smartcase
set tabstop=4
set shiftwidth=4
set expandtab
""""set autoindent
syntax enable
:highlight Pmenu ctermbg=238 gui=bold
let g:netrw_keepdir=0
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

noremap <silent> <F1>               :help<CR>
noremap <silent> <F2>               :call ToggleVExplorer()<CR>
let g:lt_quickfix_list_toggle_map = '<F3>'
let g:lt_location_list_toggle_map = '<F4>'
let g:ctrlp_map                   = '<F6>'

"---- [NORMAL KEY MAPPINGS] ----"
nnoremap <Leader><Tab>      :bnext<CR>
nnoremap <Leader><Tab><Tab> :bprevious<CR>
nnoremap <Leader><Right>    <C-w>l
nnoremap <Leader><Up>       <C-w>k
nnoremap <Leader><Down>     <C-w>j
nnoremap <Leader><Left>     <C-w>h
nnoremap <Leader>r          :q<CR>
nnoremap <Leader>rr         :bdelete<CR>
nnoremap <Leader>s          :w !sudo tee %

"""" search trailing spaces
nnoremap <Leader>w       /\s\+$<CR>

"""" comment/ uncomment in V-LINE mode
vmap <S-c>               :s/^/#/<CR> :noh<CR>
vmap <S-c><S-c>          :s/^#//<CR> :noh<CR>

" =============================================================================
" -- UNIX SPECIFIC ---- UNIX SPECIFIC ---- UNIX SPECIFIC ---- UNIX SPECIFIC ---
" =============================================================================

if has('unix')
    let g:bufferline_echo = 0
    nnoremap <Leader>+  :vertical resize +5<CR>
    nnoremap <Leader>-  :vertical resize -5<CR>
    nnoremap <Leader>n  :vertical split<CR>
    nnoremap <Leader>ne :vertical split new<CR>
endif

" =============================================================================
" -- WINDOWS SPECIFIC ---- WINDOWS SPECIFIC ---- WINDOWS SPECIFIC ---- WINDOWS
" =============================================================================

if has('win32')
endif

" =============================================================================
" -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P --
" =============================================================================

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
""""let g:airline_powerline_fonts=1

let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

let g:airline#extensions#tabline#enabled = 1

" ============================================================================= 
" -- NETRW CONFIG ---- NETRW CONFIG ---- NETRW CONFIG ---- NETRW CONFIG ---- NE 
" ============================================================================= 

function! ToggleVExplorer() 
    if exists("t:expl_buf_num") 
        unlet g:netrw_liststyle 
        """"unlet g:netrw_browse_split 
        let expl_win_num = bufwinnr(t:expl_buf_num) 
        if expl_win_num != -1 
            let cur_win_nr = winnr() 
            exec expl_win_num . 'wincmd w' 
            close 
            exec cur_win_nr . 'wincmd w' 
            unlet t:expl_buf_num 
        else 
            unlet t:expl_buf_num 
        endif 
    else 
        let g:netrw_liststyle = 2 
        """"let g:netrw_browse_split = 4 
        exec '1wincmd w' 
        Vexplore 
        let t:expl_buf_num = bufnr("%") 
    endif 
endfunction 
