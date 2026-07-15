" ---- Generics ---- "
set backspace=indent,eol,start
set number
set autoindent
set smartindent



" ---- Search ---- "
set hlsearch
set incsearch



" ---- Mappings ---- "
nmap <Leader><space> :nohlsearch<cr>
nnoremap <C-t> :NERDTreeToggle<CR>



" ---- Split management ---- "
set splitbelow
set splitright

nmap <C-J> <C-W><C-J>
nmap <C-K> <C-W><C-K>
nmap <C-H> <C-W><C-H>
nmap <C-L> <C-W><C-L>



" ---- Plugins ---- "
call plug#begin('~/.vim/plugged')                          " vim-plug | Minimalist Vim Plugin Manager.

Plug 'tpope/vim-vinegar'                                   " Combine with netrw to create a delicious salad dressing.

Plug 'preservim/nerdtree'                                  " A tree explorer plugin for vim.

Plug 'tpope/vim-surround'                                  " Quoting/parenthesizing made simple.

Plug 'ctrlpvim/ctrlp.vim'                                  " Fuzzy file, buffer, mru, tag, etc finder.

Plug 'vim-airline/vim-airline'                             " Lean & mean status/tabline for vim that's light as air.

Plug 'easymotion/vim-easymotion'                           " Vim motions on speed!

Plug 'hzchirs/vim-material'                                " Material theme.

Plug 'nathanaelkane/vim-indent-guides'                     " A Vim plugin for visually displaying indent levels in code.

Plug 'noahfrederick/vim-composer'                          " Vim support for Composer PHP projects.

call plug#end()



" ---- Theme ---- "
let g:material_style='palenight'
set background=dark
silent! colorscheme vim-material



" Automatically source vimrc on save.
augroup autosourcing
	autocmd!
	autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END
