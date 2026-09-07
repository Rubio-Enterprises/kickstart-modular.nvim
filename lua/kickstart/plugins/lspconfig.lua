local function gh(repo) return 'https://github.com/' .. repo end

-- [[ LSP Configuration ]]
-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This config does NOT install them: every server below is provisioned by
-- the dotfiles package registry (`home/.chezmoidata/packages.toml`, category
-- "core") and resolved from PATH. That registry is the single source of truth for
-- which binaries exist -- shared with the Claude Code `claude-lsps` plugins and
-- omp's `~/.omp/agent/lsp.json` -- so a server has exactly one version on this
-- machine. Mason was removed for that reason: it would install a second,
-- independently-versioned copy of tooling that is already present.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

-- Useful status updates for LSP.
vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Language servers to enable. Keys are `nvim-lspconfig` config names; the value
-- is a `vim.lsp.Config` override merged over that shipped config (`{}` = take it
-- as-is). Every binary here is declared in the dotfiles package registry, so
-- adding a server means adding it there first, not installing it from Neovim.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
  -- Web / config formats
  -- TypeScript, JavaScript, JSX/TSX.
  --
  -- vtsls implements `didRenameFiles` but NOT `willRenameFiles` (vtsls#287), so
  -- import rewriting happens after the rename, driven by the notification
  -- snacks.rename sends. tsserver's default for that is `prompt`, which blocks
  -- on a `window/showMessageRequest` every single time; `always` is what makes
  -- `<leader>cR` rewrite imports without asking.
  vtsls = {
    settings = {
      typescript = { updateImportsOnFileMove = { enabled = 'always' } },
      javascript = { updateImportsOnFileMove = { enabled = 'always' } },
    },
  },
  jsonls = {},
  yamlls = {},
  marksman = {}, -- Markdown
  tombi = {}, -- TOML

  -- Systems / infra
  gopls = {},
  rust_analyzer = {},
  terraformls = {},
  bashls = {},
  regal = {}, -- Rego
  cue = {},

  -- sourcekit also claims c/cpp/objc/objcpp, not just swift. That is upstream's
  -- default and is correct on this machine: the C headers here belong to Xcode
  -- projects, and no clangd is installed to compete for those filetypes.
  sourcekit = {},

  -- Python is split: pyright owns types, ruff owns lint/format/imports. Ruff's
  -- hover is disabled below so the two do not both answer `K`.
  pyright = {},
  ruff = {
    on_attach = function(client) client.server_capabilities.hoverProvider = false end,
  },

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      -- Formatting is stylua's job, wired up in conform.lua.
      client.server_capabilities.documentFormattingProvider = false

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- see the note in on_init above
      },
    },
  },
}

vim.pack.add { gh 'neovim/nvim-lspconfig' }

-- Nvim's default client capabilities set every `workspace.fileOperations` flag
-- to false, so servers never register `workspace/willRenameFiles` and a file
-- rename silently rewrites no imports. Opt in for every server: this is what
-- makes `<leader>cR` (snacks.rename) actually fix up import paths.
vim.lsp.config('*', {
  capabilities = {
    workspace = {
      fileOperations = { willRename = true, didRename = true },
    },
  },
})

-- Enable only the servers whose binary is actually present. A missing binary
-- would otherwise fail on every matching buffer; skipping keeps a half-applied
-- machine quiet instead of noisy, and `:checkhealth lsp` still reports the gap.
for name, server in pairs(servers) do
  local cmd = vim.lsp.config[name] and vim.lsp.config[name].cmd
  local bin = type(cmd) == 'table' and cmd[1] or nil
  if bin == nil or vim.fn.executable(bin) == 1 then
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- vim: ts=2 sts=2 sw=2 et
