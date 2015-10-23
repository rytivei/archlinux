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

"---- [github] ----"
Bundle 'gmarik/vundle'
Bundle 'bling/vim-airline'
Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/syntastic'
Bundle 'airblade/vim-gitgutter'
Bundle 'valloric/listtoggle'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-commentary'
Bundle 'majutsushi/tagbar'
Bundle 'ervandew/supertab'

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
set omnifunc=syntaxcomplete#Complete
syntax enable
:highlight Pmenu ctermbg=238 gui=bold
let mapleader = "§"


augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

"""" set working directory to current file in current window
autocmd BufEnter * silent! lcd %:p:h

" =============================================================================
" -- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBINDINGS ---- KEYBIN
" =============================================================================

"---- [FUNCTION KEY MAPPINGS] ----"
nnoremap <F1>                     :vertical help<Space>
nnoremap <silent><F2>             :TagbarToggle<CR>
let g:ctrlp_map                   = '<F3>'
let g:lt_quickfix_list_toggle_map = '<F5>'
let g:lt_location_list_toggle_map = '<F6>'

"---- [NORMAL KEY MAPPINGS] ----"
nnoremap <Leader><Tab>      :bnext!<CR>
nnoremap <Leader><Right>    <C-w>l
nnoremap <Leader><Up>       <C-w>k
nnoremap <Leader><Down>     <C-w>j
nnoremap <Leader><Left>     <C-w>h
nnoremap <Leader>r          :q<CR>
nnoremap <Leader>rr         :bdelete<CR>
nnoremap <Leader>v          :Vexplore<CR>

"""" open with sudo
nnoremap <Leader>s          :w !sudo tee %

"""" search trailing spaces
nnoremap <Leader>w           /\s\+$<CR>

"---- [PLUGIN MAPPINGS] ----"

"""" vim-airline
nmap <Leader>1 <Plug>AirlineSelectTab1
nmap <Leader>2 <Plug>AirlineSelectTab2
nmap <Leader>3 <Plug>AirlineSelectTab3
nmap <Leader>4 <Plug>AirlineSelectTab4
nmap <Leader>5 <Plug>AirlineSelectTab5
nmap <Leader>6 <Plug>AirlineSelectTab6
nmap <Leader>7 <Plug>AirlineSelectTab7
nmap <Leader>8 <Plug>AirlineSelectTab8
nmap <Leader>9 <Plug>AirlineSelectTab9

"""" gitgutter
nnoremap <Leader>g :GitGutterLineHighlightsToggle<CR>

" =============================================================================
" -- UNIX SPECIFIC ---- UNIX SPECIFIC ---- UNIX SPECIFIC ---- UNIX SPECIFIC ---
" =============================================================================

if has('unix')
    "---- [NORMAL KEY MAPPINGS] ----"
    nnoremap <Leader>+  :vertical resize +10<CR>
    nnoremap <Leader>-  :vertical resize -10<CR>
    nnoremap <Leader>n  :vertical split<CR>
    nnoremap <Leader>ne :vertical split new<CR>
endif

" =============================================================================
" -- WINDOWS SPECIFIC ---- WINDOWS SPECIFIC ---- WINDOWS SPECIFIC ---- WINDOWS
" =============================================================================

if has('win32')
endif

" =============================================================================
" -- STATUS LINE ---- STATUS LINE ---- STATUS LINE ---- STATUS LINE ---- STATUS
" =============================================================================

set laststatus=2
set t_Co=256

if !exists('g:airline_symbols')
let g:airline_symbols = {}
endif

let g:airline_theme='murmur'
let g:airline_detect_paste = 1
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

"""" extensions
let g:airline#extensions#tabline#buffer_idx_mode = 1
let g:airline#extensions#quickfix#quickfix_text = 'QuickFix'
let g:airline#extensions#quickfix#location_text = 'SearchList'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#ctrlp#color_template = 'visual'

" =============================================================================
" -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P -- -- CTRL-P --
" =============================================================================

let g:ctrlp_cmd     = 'call ToggleCtrlP()'
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
" -- NETRW CONFIG ---- NETRW CONFIG ---- NETRW CONFIG ---- NETRW CONFIG ---- NE
" =============================================================================

let g:netrw_keepdir   = 0
let g:netrw_chgwin    = 1
let g:netrw_liststyle = 0 " thin (change to 3 for tree)
let g:netrw_altv      = 1 " open files on right
let g:netrw_preview   = 1 " open previews vertically

" =============================================================================
" -- SYNTASTIC ---- SYNTASTIC ---- SYNTASTIC ---- SYNTASTIC ---- SYNTASTIC ----
" =============================================================================

let g:syntastic_enable_signs = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_python_python_exec = 'python3'
