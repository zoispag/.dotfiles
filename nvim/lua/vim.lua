vim.cmd 'set expandtab'
vim.cmd 'set tabstop=2'
vim.cmd 'set softtabstop=2'
vim.cmd 'set shiftwidth=2'

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.background = 'light'

vim.opt.swapfile = false

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>', { desc = '↑' })
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>', { desc = '↓' })
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>', { desc = '←' })
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>', { desc = '→' })

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
vim.wo.number = true
