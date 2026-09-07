local function gh(repo) return 'https://github.com/' .. repo end

-- Useful plugin to show you pending keybinds.
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  -- Delay between pressing a key and opening which-key (milliseconds)
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  -- Document existing key chains
  spec = {
    { '<leader>b', group = '[B]uffer' },
    { '<leader>c', group = '[C]ode' },
    { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
    { '<leader>n', group = '[N]otifications' },
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

-- vim: ts=2 sts=2 sw=2 et
