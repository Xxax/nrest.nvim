-- nrest.nvim Docker Demo Configuration
-- Minimal Neovim setup optimized for testing nrest.nvim

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings for a comfortable experience
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = false  -- Disable relative line numbers
vim.opt.cursorline = true       -- Highlight current line
vim.opt.wrap = false            -- Don't wrap lines
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.shiftwidth = 2          -- Indent width
vim.opt.tabstop = 2             -- Tab width
vim.opt.smartindent = true      -- Smart indentation
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.mouse = "a"             -- Enable mouse support
vim.opt.termguicolors = true    -- Enable 24-bit colors
vim.opt.signcolumn = "yes"      -- Always show sign column
vim.opt.updatetime = 300        -- Faster completion
vim.opt.timeoutlen = 1000       -- 1 second for key sequences (easier for demos/beginners)

-- Split behavior
vim.opt.splitbelow = true       -- Horizontal splits go below
vim.opt.splitright = true       -- Vertical splits go right

-- Search settings
vim.opt.ignorecase = true       -- Ignore case in search
vim.opt.smartcase = true        -- Case-sensitive if uppercase present

-- Disable swap and backup files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Setup lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configure plugins
require("lazy").setup({
  -- nrest.nvim - HTTP REST client
  {
    dir = "/home/nvim/.local/share/nvim/nrest",
    name = "nrest.nvim",
    ft = "http",
    config = function()
      require("nrest").setup({
        -- Result window configuration
        result_split_horizontal = false,  -- Vertical split

        -- Request settings
        skip_ssl_verification = false,    -- Keep SSL verification enabled
        timeout = 10000,                  -- 10 second timeout

        -- Response formatting
        format_response = true,           -- Format JSON with jq

        -- Environment variables
        env_file = 'auto',                -- Auto-discover .env.http

        -- Syntax highlighting
        highlight = {
          enabled = true,
          timeout = 150,
        },

        -- Result display
        result = {
          show_url = true,
          show_http_info = true,
          show_headers = true,
          show_body = true,
          folding = true,
        },

        -- Keybindings
        keybindings = {
          run_request = '<leader>rr',
          run_request_under_cursor = '<leader>rc',
        },
      })

      -- Print welcome message
      vim.defer_fn(function()
        print("🚀 nrest.nvim Demo Environment")
        print("📖 Press <leader>rc to execute request under cursor")
        print("📖 Press <leader>rr to execute first request")
        print("💡 Use :NrestRunCursor or :NrestRun commands")
        print("❓ Run :checkhealth nrest for diagnostics")
      end, 100)
    end,
  },

  -- Colorscheme for better visibility
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          section_separators = "",
          component_separators = "|",
        },
        sections = {
          lualine_a = {"mode"},
          lualine_b = {"branch"},
          lualine_c = {"filename"},
          lualine_x = {"filetype"},
          lualine_y = {"progress"},
          lualine_z = {"location"},
        },
      })
    end,
  },
})

-- Custom keymaps
local keymap = vim.keymap.set

-- General keymaps
keymap("n", "<leader>q", ":qa<CR>", { desc = "Quit all" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>e", ":e .<CR>", { desc = "File explorer" })

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Help commands for nrest.nvim
vim.api.nvim_create_user_command("NrestHelp", function()
  print("=== nrest.nvim Quick Reference ===")
  print("")
  print("Commands:")
  print("  :NrestRun          - Execute first request in file")
  print("  :NrestRunCursor    - Execute request under cursor")
  print("  :checkhealth nrest - Check plugin health")
  print("")
  print("Keybindings:")
  print("  <leader>rr - Run first request")
  print("  <leader>rc - Run request under cursor")
  print("")
  print("Example Request:")
  print("  ### My Request")
  print("  GET https://httpbin.org/get")
  print("  Accept: application/json")
  print("")
  print("See welcome.http for more examples!")
end, {})

-- Auto-command to show help on first .http file open
vim.api.nvim_create_autocmd("FileType", {
  pattern = "http",
  once = true,
  callback = function()
    vim.defer_fn(function()
      vim.cmd("NrestHelp")
    end, 200)
  end,
})
