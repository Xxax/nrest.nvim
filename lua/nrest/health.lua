local M = {}

--- Health check for nrest.nvim
--- Run with :checkhealth nrest
function M.check()
  -- Use vim.health for Neovim 0.10+, fallback to require('health') for 0.9
  local health = vim.health or require('health')

  health.start('nrest.nvim')

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor >= 8 then
    health.ok(string.format('Neovim version: %d.%d.%d', nvim_version.major, nvim_version.minor, nvim_version.patch))
  else
    health.error(string.format(
      'Neovim version %d.%d.%d is too old. Requires Neovim >= 0.8.0',
      nvim_version.major,
      nvim_version.minor,
      nvim_version.patch
    ))
  end

  -- Check curl (required)
  if vim.fn.executable('curl') == 1 then
    local curl_version = vim.fn.system('curl --version'):match('curl ([%d%.]+)')
    health.ok('curl is installed' .. (curl_version and ': ' .. curl_version or ''))
  else
    health.error('curl is not installed', {
      'curl is required for executing HTTP requests',
      'Install curl: https://curl.se/download.html',
      '  - macOS: brew install curl',
      '  - Ubuntu/Debian: sudo apt-get install curl',
      '  - Arch: sudo pacman -S curl',
    })
  end

  -- Check jq (optional, for JSON formatting)
  if vim.fn.executable('jq') == 1 then
    local jq_version = vim.fn.system('jq --version'):match('jq%-([%d%.]+)')
    health.ok('jq is installed' .. (jq_version and ': ' .. jq_version or '') .. ' (optional, for JSON formatting)')
  else
    health.warn('jq is not installed (optional)', {
      'jq is used for pretty-printing JSON responses',
      'Install jq: https://stedolan.github.io/jq/download/',
      '  - macOS: brew install jq',
      '  - Ubuntu/Debian: sudo apt-get install jq',
      '  - Arch: sudo pacman -S jq',
      'JSON responses will be displayed without formatting if jq is not available',
    })
  end

  -- Check base64 (used for Basic Auth fallback, but we have pure Lua implementation)
  if vim.fn.executable('base64') == 1 then
    health.ok('base64 is available (not required, using pure Lua implementation)')
  else
    health.info('base64 not found (using pure Lua implementation for Basic Auth)')
  end

  -- Check plugin configuration
  local ok, nrest = pcall(require, 'nrest')
  if ok then
    health.ok('nrest.nvim is loaded')

    -- Check config
    if nrest.config then
      health.info('Configuration:')
      health.info('  - result_split_horizontal: ' .. tostring(nrest.config.result_split_horizontal))
      health.info('  - skip_ssl_verification: ' .. tostring(nrest.config.skip_ssl_verification))
      health.info('  - timeout: ' .. tostring(nrest.config.timeout) .. 'ms')
      health.info('  - format_response: ' .. tostring(nrest.config.format_response))
      health.info('  - env_file: ' .. tostring(nrest.config.env_file or 'nil'))
    end
  else
    health.warn('nrest.nvim is not loaded', {
      'Run :lua require("nrest").setup() in your init.lua',
    })
  end

  -- Check filetype detection
  vim.cmd('silent! filetype detect')
  local test_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(test_buf, 'test.http')
  local ft = vim.bo[test_buf].filetype
  vim.api.nvim_buf_delete(test_buf, { force = true })

  if ft == 'http' then
    health.ok('Filetype detection working (.http files detected)')
  else
    health.warn('Filetype detection may not be working', {
      'Ensure filetype detection is enabled: :filetype on',
    })
  end

  -- Check for common issues
  health.start('Common Issues')

  -- Check if snacks.nvim is installed (for compatibility notes)
  local has_snacks = pcall(require, 'snacks')
  if has_snacks then
    health.info('snacks.nvim detected - nrest.nvim includes compatibility workarounds')
  end

  -- Check if AstroNvim is detected
  if vim.g.astronvim_version then
    health.info('AstroNvim detected - nrest.nvim includes compatibility workarounds')
  end

  health.ok('No common issues detected')
end

return M
