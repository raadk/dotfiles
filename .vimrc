set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'dracula/vim'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'nanotech/jellybeans.vim'
Plugin 'klen/python-mode'
Plugin 'vim-scripts/vim-auto-save'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'JamshedVesuna/vim-markdown-preview'
Plugin 'mbbill/undotree'
Plugin 'majutsushi/tagbar'
Plugin 'junegunn/goyo.vim'
Plugin 'junegunn/limelight.vim'
Plugin 'othree/html5.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'Yggdroot/indentLine'
Plugin 'Valloric/MatchTagAlways'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-surround'
Plugin 'jpalardy/vim-slime'
Plugin 'lervag/vimtex'

"Plugin 'dense-analysis/ale'


"Plugin 'suan/vim-instant-markdown'
"Plugin 'stephpy/vim-yaml'
"Plugin 'vim-syntastic/syntastic'
"Plugin 'altercation/vim-colors-solarized'
"Plugin 'morhetz/gruvbox'
"Plugin 'itchyny/lightline.vim'
"Plugin 'honza/vim-snippets'
"Plugin 'wesgibbs/vim-irblack'
"Plugin 'plytophogy/vim-virtualenv'
"Plugin 'jalvesaq/Nvim-R'
call vundle#end()
filetype plugin indent on

" Change leader
let mapleader=','

" Trailing whitespace
fun! TrimWhitespace()
    let l:save = winsaveview()
    %s/\s\+$//e
    call winrestview(l:save)
endfun

" Filetype specific plugin settings
au FileType python,html,css,less,js autocmd vimenter * NERDTree | wincmd p
au FileType python,html,css,less,js let g:nerdtree_tabs_open_on_console_startup = 1
au FileType html,css,less,js let g:indentLine_enabled = 1

" Plugin settings
let g:slime_target = "tmux"
let g:slime_python_ipython = 1
let g:slime_default_config = {"socket_name": "default", "target_pane": ":0.1"}


let g:auto_save = 1 " Not sure I like this
let g:auto_save_in_insert_mode = 0

"let g:pymode_python = 'python3'
let g:pymode_folding = 0
"let g:pymode_lint = 0 " Switch to syntastic
let g:pymode_lint_on_write = 0
let g:pymode_rope_completion = 1
let g:pymode_rope_complete_on_dot = 0
let g:pymode_rope_completion_bind = '<C-N>'
let g:pymode_rope_rename_bind = '<Leader>rn'

let g:indentLine_enabled = 0

let g:vim_markdown_folding_disabled = 1
"let vim_markdown_preview_github=0
let vim_markdown_preview_pandoc=1
let vim_markdown_preview_browser='Google Chrome'
let g:vim_markdown_math = 1


"let vim_markdown_preview_toggle=2

" let vim_markdown_preview_pandoc=1
" let vim_markdown_preview_toggle=1
" let vim_markdown_preview_temp_file=1
" let vim_markdown_preview_use_xdg_open=1

let g:tex_flavor='latex'
"let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=2
let g:tex_conceal='abdmg'
let g:vimtex_compiler_latexmk = {'build_dir' : 'latexbuild',}

let g:airline#extensions#tagbar#enabled = 0

" Limelight
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240



" Quote word
map <Leader>dq ysiw"
map <Leader>sq ysiw'

" Quick access
let vim_markdown_preview_hotkey='<Leader>md'
set pastetoggle=<Leader>pp

nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
nnoremap <Leader>pl :PymodeLint<CR>
nnoremap <Leader>ut :UndotreeToggle<CR>
nnoremap <Leader>tb :TagbarToggle<CR>
nnoremap <Leader>gy :Goyo<CR>
nnoremap <Leader>gyl :set wrap <CR> :set linebreak <CR> :Limelight <CR> :setlocal spell <CR> :Goyo<CR> 
nnoremap <Leader>gyq  :Goyo! <CR> :set nowrap <CR> :set nolinebreak <CR> :Limelight! <CR> :setlocal nospell <CR> 

nnoremap <Leader>ll :Limelight!!<CR>
nnoremap <Leader>il :IndentLinesToggle<CR>
nnoremap <Leader>tws :call TrimWhitespace()<CR>
nnoremap <Leader>rt :retab<CR>
nnoremap <Leader>sw :set wrap! <CR> :set linebreak!<CR> 
nnoremap <Leader>nh :nohlsearch<CR>
nnoremap <Leader>aa ggVG
nnoremap <leader>np :e ~/buffer.md<cr>
nnoremap <leader>op :!open %<cr>

nnoremap <leader>ht Vggo

map <Leader>sc :setlocal spell!<CR>
map <leader>scn ]s
map <leader>scp [s
map <leader>sca zg
map <leader>sc? z=

nnoremap <Leader>dt :r !date<Esc>
nnoremap <Leader>hr 10i-<Esc>

vnoremap <Leader>c "+y
nnoremap <Leader>c V"+y<Esc>
inoremap <Leader>cc <ESC>V"+y<Esc>i
nnoremap <Leader>v <Leader>ppi<C-r>+<ESC><Leader>pp
inoremap <Leader>vv <Leader>pp<C-r>+<ESC><Leader>pp i

command! W w
command! Q q
command! WQ wq
command! Wq wq

" Syntastic
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" Disable error bells
set noerrorbells

" Store more history
set history=100

" Show title in window
set title

" Save swps in a different place
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

" Confirm save before exiting
set confirm

" Allow for some mouse actions
set mouse=a

" Colorscheme
set background=dark
" colorscheme torte
color jellybeans

" Change tabs easily
noremap <S-l> gt
noremap <S-h> gT

" Default split action
set splitbelow
set splitright

" 256 colors
set t_Co=256

" sane text files
set fileformat=unix
set encoding=utf-8

" sane tabs
set tabstop=4
set shiftwidth=4
set softtabstop=4

" convert all typed tabs to spaces
set expandtab

" syntax highlighting
syntax on

"make sure highlighting works all the way down long files
autocmd BufEnter * :syntax sync fromstart

" allow cursor to be positioned one char past end of line
" and apply operations to all of selection including last char
set selection=exclusive

" allow backgrounding buffers without writing them
" and remember marks/undo for backgrounded buffers
set hidden

" Keep more context when scrolling off the end of a buffer
set scrolloff=3

" allow cursor keys to go right off end of one line, onto start of next
set whichwrap+=<,>,[,]

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" no line wrapping
set nowrap

" line numbers
set number

" when joining lines, don't insert two spaces after punctuation
set nojoinspaces

" Make searches case-sensitive only if they contain upper-ase characters
set ignorecase
set smartcase
" show search matches as the search pattern is typed
set incsearch
" search-next wraps back to start of file
set wrapscan
" highlight last search matches
set hlsearch
" map key to dismiss search highlightedness
map <bs> :noh<CR>

" grep for word under cursor
noremap <Leader>g :grep -rw '<C-r><C-w>' .<CR>

" aliases for window switching (browser captures ctrl-w)
noremap <C-l> <C-w>l
noremap <C-h> <C-w>h
noremap <C-k> <C-w>k
noremap <C-j> <C-w>j

" similarly ctrl-q doesnt work, so use leader-q for block visual mode
nnoremap <leader>q <C-Q>

" make tab completion for files/buffers act like bash
set wildmenu

" display cursor co-ords at all times
set ruler
set cursorline

" display number of selected chars, lines, or size of blocks.
set showcmd

" show matching brackets, etc, for 1/10th of a second
set showmatch
set matchtime=1

" enables filetype specific plugins
filetype plugin on
" enables filetype detection
filetype on

if has("autocmd")
    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
    filetype plugin indent on

   " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
else
    " if old vim, set vanilla autoindenting on
    set autoindent

endif " has("autocmd")

" enable automatic yanking to and pasting from the selection
set clipboard+=unnamed

" places to look for tags files:
set tags=./tags,tags
" recursively search file's parent dirs for tags file
" set tags+=./tags;/
" recursively search cwd's parent dirs for tags file
set tags+=tags;/

"autocompletion
inoremap<c-space> <c-n>
inoremap <c-s-space> <c-p>

" Section ---
fun! Header(word)
    let a:width = 81
    let a:inserted_word = '# ' . a:word . ' '
    let a:word_width = strlen(a:inserted_word)
    let a:hashes_after = repeat('-', a:width - (a:word_width + 2))
    let a:word_line = a:inserted_word . a:hashes_after
    :put =a:word_line
endfunction

command! -nargs=* Section :call Header(<q-args>)
