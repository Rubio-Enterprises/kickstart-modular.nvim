local function gh(repo) return 'https://github.com/' .. repo end

-- [[ snacks.nvim ]]
-- A modern collection of small QoL plugins for Neovim.
-- https://github.com/folke/snacks.nvim

vim.pack.add {
  gh 'folke/snacks.nvim',
}

require('snacks').setup {
  -- Tier 1: Core modern utilities
  bigfile = { enabled = true },
  bufdelete = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  picker = { enabled = true },
  rename = { enabled = true },

  -- Indent guide lines & scope tracking
  indent = { enabled = true },

  -- Statuscolumn: clean signs, numbers, and clickable folds
  statuscolumn = { enabled = true },

  -- Git integration.
  --
  -- `gitbrowse` builds the web URL from `git remote -v`, which git prints AFTER
  -- applying `url.<base>.insteadOf`. The dotfiles rewrite personal-owner repos
  -- onto the `git@github-personal:` SSH host alias (dual GitHub account key
  -- selection), so the rewritten remote carries a hostname that does not exist
  -- on the web. The stored remote is still canonical `github.com`.
  --
  -- Map any `git@github-<alias>:` host back to github.com before the URL
  -- patterns run. `remote_patterns` is a list, so it replaces the default
  -- wholesale -- the upstream entries are repeated verbatim below the alias rule.
  gitbrowse = {
    enabled = true,
    -- stylua: ignore
    remote_patterns = {
      { '^git@github%-[%w_%-]+:(.+)$'       , 'https://github.com/%1' },
      { '^(https?://.*)%.git$'              , '%1' },
      { '^git@(.+):(.+)%.git$'              , 'https://%1/%2' },
      { '^git@(.+):(.+)$'                   , 'https://%1/%2' },
      { '^git@(.+)/(.+)$'                   , 'https://%1/%2' },
      { '^org%-%d+@(.+):(.+)%.git$'         , 'https://%1/%2' },
      { '^ssh://git@(.*)$'                  , 'https://%1' },
      { '^ssh://([^:/]+)(:%d+)/(.*)$'       , 'https://%1/%3' },
      { '^ssh://([^/]+)/(.*)$'              , 'https://%1/%2' },
      { 'ssh%.dev%.azure%.com/v3/(.*)/(.*)$', 'dev.azure.com/%1/_git/%2' },
      { '^https://%w*@(.*)'                 , 'https://%1' },
      { '^git@(.*)'                         , 'https://%1' },
      { ':%d+'                              , '' },
      { '%.git$'                            , '' },
    },
  },
}

-- [[ Picker Keymaps ]]
-- Fuzzy find files, text, buffers, diagnostics, and more
local picker = Snacks.picker
vim.keymap.set('n', '<leader>sh', function() picker.help() end, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', function() picker.keymaps() end, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() picker.files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', function() picker.pickers() end, { desc = '[S]earch [S]elect Picker' })
vim.keymap.set({ 'n', 'x' }, '<leader>sw', function() picker.grep_word() end, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', function() picker.grep() end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', function() picker.diagnostics() end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', function() picker.resume() end, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', function() picker.recent() end, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', function() picker.commands() end, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', function() picker.buffers() end, { desc = '[ ] Find existing buffers' })

-- Buffer line search and open files grep
vim.keymap.set('n', '<leader>/', function() picker.lines() end, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>s/', function() picker.grep_buffers() end, { desc = '[S]earch [/] in Open Files' })

-- Shortcut for searching Neovim configuration files
vim.keymap.set('n', '<leader>sn', function() picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

-- Add Snacks-based LSP pickers when an LSP attaches to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('snacks-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- Find references for the word under cursor
    vim.keymap.set('n', 'grr', function() picker.lsp_references() end, { buffer = buf, desc = '[G]oto [R]eferences' })

    -- Jump to implementation
    vim.keymap.set('n', 'gri', function() picker.lsp_implementations() end, { buffer = buf, desc = '[G]oto [I]mplementation' })

    -- Jump to definition
    vim.keymap.set('n', 'grd', function() picker.lsp_definitions() end, { buffer = buf, desc = '[G]oto [D]efinition' })

    -- Fuzzy find all symbols in current document
    vim.keymap.set('n', 'gO', function() picker.lsp_symbols() end, { buffer = buf, desc = 'Open Document Symbols' })

    -- Fuzzy find all symbols in workspace
    vim.keymap.set('n', 'gW', function() picker.lsp_workspace_symbols() end, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- Jump to type definition
    vim.keymap.set('n', 'grt', function() picker.lsp_type_definitions() end, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

-- [[ Buffer Management ]]
-- Close current buffer without closing the split window
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = '[B]uffer [D]elete' })

-- [[ File / Symbol Renaming ]]
-- Rename the current file and automatically update LSP imports across the project
vim.keymap.set('n', '<leader>cR', function() Snacks.rename.rename_file() end, { desc = '[R]ename File (LSP)' })

-- [[ Git Integration ]]
-- Open current file, line, or visual selection in GitHub / GitLab
vim.keymap.set({ 'n', 'v' }, '<leader>gb', function() Snacks.gitbrowse() end, { desc = '[G]it [B]rowse in browser' })

-- [[ Notifier ]]
-- Notification history and dismiss
vim.keymap.set('n', '<leader>nh', function() Snacks.notifier.show_history() end, { desc = '[N]otification [H]istory' })
vim.keymap.set('n', '<leader>nd', function() Snacks.notifier.hide() end, { desc = '[N]otifications [D]ismiss' })

-- vim: ts=2 sts=2 sw=2 et
