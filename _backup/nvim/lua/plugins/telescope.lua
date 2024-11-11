return {
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.8',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-ui-select.nvim' },
		},
		config = function()
			require('telescope').setup {
				extensions = {
					['ui-select'] = {
						require('telescope.themes').get_dropdown {},
					},
				},
			}

			local builtin = require 'telescope.builtin'

			vim.keymap.set('n', '<leader>P', builtin.find_files, { desc = 'Telescope find files' })
			vim.keymap.set('n', '<leader>B', builtin.buffers, { desc = 'Telescope buffers' })
			vim.keymap.set('n', '<leader>F', builtin.live_grep, { desc = 'Telescope live grep' })

			require('telescope').load_extension 'ui-select'
		end,
	},
}
