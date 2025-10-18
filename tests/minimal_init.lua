-- Minimal init for running tests with plenary.nvim
-- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

-- Add current directory to runtimepath
vim.cmd([[set rtp+=.]])

-- Add plenary.nvim to runtimepath (adjust path as needed)
-- Install plenary with: git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
vim.cmd([[set rtp+=~/.local/share/nvim/site/pack/vendor/start/plenary.nvim]])

-- Ensure we can require our modules
vim.opt.runtimepath:append('.')

-- Set up environment for testing
vim.env.PLENARY_TEST_TIMEOUT = 5000
