local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Formatting ]]
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- You can specify filetypes to autoformat on save here:
    local enabled_filetypes = {
      -- lua = true,
      -- python = true,
    }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 500 }
    else
      return nil
    end
  end,
  default_format_opts = {
    lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
  },
  -- External formatters. Same rule as the language servers: every binary here
  -- is declared in the dotfiles package registry (`packages.toml`, category
  -- "core") and resolved from PATH, so the editor formats with the exact
  -- binaries lefthook runs at commit time. Nothing is installed from Neovim.
  --
  -- `stop_after_first` on the JS/TS family: repos here are biome-first, but the
  -- ones that predate that still carry a prettier config, and running both would
  -- have the second undo the first.
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_format', 'ruff_organize_imports' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    javascript = { 'biome', 'prettier', stop_after_first = true },
    javascriptreact = { 'biome', 'prettier', stop_after_first = true },
    typescript = { 'biome', 'prettier', stop_after_first = true },
    typescriptreact = { 'biome', 'prettier', stop_after_first = true },
    json = { 'biome', 'prettier', stop_after_first = true },
    jsonc = { 'biome', 'prettier', stop_after_first = true },
    css = { 'prettier' },
    html = { 'prettier' },
    yaml = { 'prettier' },
    markdown = { 'prettier' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- vim: ts=2 sts=2 sw=2 et
