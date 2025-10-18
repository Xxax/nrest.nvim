local M = {}

-- Show HTTP response in a split window
function M.show_response(response, config)
  if not response.success then
    vim.notify('Request failed: ' .. (response.error or 'Unknown error'), vim.log.levels.ERROR)
    return
  end

  -- Create or reuse result buffer
  local result_buf = M.get_or_create_result_buffer()

  -- Format response content
  local lines = M.format_response(response, config)

  -- Set buffer content
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, lines)

  -- Set buffer options
  vim.api.nvim_buf_set_option(result_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(result_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(result_buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(result_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(result_buf, 'filetype', 'http-result')

  -- Show buffer in split
  M.show_buffer_in_split(result_buf, config)

  -- Apply syntax highlighting
  if config.highlight.enabled then
    M.apply_syntax_highlighting(result_buf)
  end
end

-- Get or create result buffer
function M.get_or_create_result_buffer()
  -- Check if result buffer already exists
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('nrest%-result') then
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        return buf
      end
    end
  end

  -- Create new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, 'nrest-result')
  return buf
end

-- Show buffer in split window
function M.show_buffer_in_split(buf, config)
  -- Check if buffer is already visible
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  -- Create split
  if config.result_split_horizontal then
    vim.cmd('split')
  else
    vim.cmd('vsplit')
  end

  -- Show buffer
  vim.api.nvim_win_set_buf(0, buf)
end

-- Format response for display
function M.format_response(response, config)
  local lines = {}

  -- Add status line
  if config.result.show_http_info then
    table.insert(lines, '# ' .. response.status_line)
    table.insert(lines, '')
  end

  -- Add headers
  if config.result.show_headers and next(response.headers) ~= nil then
    table.insert(lines, '## Headers')
    table.insert(lines, '')
    for key, value in pairs(response.headers) do
      table.insert(lines, key .. ': ' .. value)
    end
    table.insert(lines, '')
  end

  -- Add body
  if config.result.show_body and response.body then
    table.insert(lines, '## Body')
    table.insert(lines, '')

    -- Split body into lines
    for line in response.body:gmatch('[^\n]+') do
      table.insert(lines, line)
    end
  end

  return lines
end

-- Apply syntax highlighting to result buffer
function M.apply_syntax_highlighting(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[
      syntax match httpResultHeader /^##.*/
      syntax match httpResultStatus /^#.*/
      syntax match httpResultHeaderKey /^[^:]\+:/

      highlight default link httpResultHeader Title
      highlight default link httpResultStatus Comment
      highlight default link httpResultHeaderKey Keyword
    ]])
  end)
end

return M
