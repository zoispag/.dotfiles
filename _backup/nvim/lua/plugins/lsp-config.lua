return {
	{
		'williamboman/mason.nvim',
		lazy = false,
		config = function()
			require('mason').setup()
		end,
	},
	{
		'williamboman/mason-lspconfig.nvim',
		lazy = false,
		opts = {
			auto_install = true,
		},
	},
	{
		'neovim/nvim-lspconfig',
		lazy = false,
		config = function()
			local lspconfig = require 'lspconfig'
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

			require('mason').setup {}
			require('mason-lspconfig').setup {
				ensure_installed = { 'lua_ls' },
			}

			require('mason-lspconfig').setup_handlers {
				-- This is a default handler that will be called for each installed server (also for new servers that are installed during a session)
				function(server)
					lspconfig[server].setup {
						capabilities = capabilities,
					}
				end,
			}

			vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP: hover' })
			vim.keymap.set('n', '<leader>ld', vim.lsp.buf.definition, { desc = 'LSP: definition' })
			vim.keymap.set('n', '<leader>lr', vim.lsp.buf.references, { desc = 'LSP: references' })
			vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { desc = 'LSP: Code Action' })
		end,
	},
}
