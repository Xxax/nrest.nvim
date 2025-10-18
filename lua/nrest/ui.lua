local M = {}

-- Store buffer reference (will be nil if buffer is deleted)
local result_buffer = nil

-- Show HTTP response in a split window
function M.show_response(response, config)
  if not response.success then
    vim.notify('Request failed: ' .. (response.error or 'Unknown error'), vim.log.levels.ERROR)
    return
  end

  -- Create or reuse result buffer
  local result_buf = M.get_or_create_result_buffer()

  -- Verify buffer is valid
  if not vim.api.nvim_buf_is_valid(result_buf) then
    vim.notify('Failed to create result buffer', vim.log.levels.ERROR)
    return
  end

  -- Format response content
  local lines = M.format_response(response, config)

  -- Ensure buffer is modifiable before setting content
  vim.bo[result_buf].modifiable = true

  -- Set buffer content
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, lines)

  -- Set buffer options (using modern API)
  vim.bo[result_buf].buftype = 'nofile'
  vim.bo[result_buf].bufhidden = 'hide'
  vim.bo[result_buf].swapfile = false
  vim.bo[result_buf].filetype = 'http-result'
  vim.bo[result_buf].modifiable = false

  -- Show buffer in split
  M.show_buffer_in_split(result_buf, config)

  -- Apply syntax highlighting
  if config.highlight.enabled then
    M.apply_syntax_highlighting(result_buf)
  end
end

-- Get or create result buffer
function M.get_or_create_result_buffer()
  -- Check if cached buffer is still valid
  if result_buffer and vim.api.nvim_buf_is_valid(result_buffer) then
    vim.bo[result_buffer].modifiable = true
    return result_buffer
  end

  -- Buffer is invalid, clear cache
  result_buffer = nil

  -- Check if a result buffer exists (by name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('nrest%-result') then
        result_buffer = buf
        vim.bo[buf].modifiable = true
        return buf
      end
    end
  end

  -- Create new buffer (listed=true to prevent dashboard from showing)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, 'nrest-result')

  -- Set buffer options immediately
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false  -- Hide from buffer list

  -- Set up autocmd to clear cache when buffer is deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = buf,
    callback = function()
      if result_buffer == buf then
        result_buffer = nil
      end
    end,
  })

  result_buffer = buf
  return buf
end

-- Show buffer in split window
function M.show_buffer_in_split(buf, config)
  -- Verify buffer is valid
  if not vim.api.nvim_buf_is_valid(buf) then
    vim.notify('Invalid result buffer', vim.log.levels.ERROR)
    return
  end

  -- Check if buffer is already visible
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local win_buf = vim.api.nvim_win_get_buf(win)
      if win_buf == buf then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
  end

  -- Save current window
  local current_win = vim.api.nvim_get_current_win()

  -- Disable dashboard autocmds temporarily to prevent interference
  local eventignore = vim.o.eventignore
  vim.o.eventignore = 'all'

  -- Create split using API
  local split_cmd = config.result_split_horizontal and 'split' or 'vsplit'

  -- Use pcall to catch any errors during split creation
  local ok, err = pcall(function()
    vim.cmd(split_cmd)
    local new_win = vim.api.nvim_get_current_win()

    -- Re-enable events before setting buffer
    vim.o.eventignore = eventignore

    -- Verify we got a new window and it's valid
    if new_win and vim.api.nvim_win_is_valid(new_win) and new_win ~= current_win then
      vim.api.nvim_win_set_buf(new_win, buf)
    else
      -- Fallback: try to set buffer in current window
      vim.api.nvim_win_set_buf(current_win, buf)
    end
  end)

  -- Ensure eventignore is restored even if there's an error
  vim.o.eventignore = eventignore

  if not ok then
    vim.notify('Error opening result window: ' .. tostring(err), vim.log.levels.ERROR)
  end
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

    -- Format body based on content type
    local formatted_body = M.format_body(response.body, response.headers, config)

    -- Split formatted body into lines and remove CR characters
    for line in formatted_body:gmatch('([^\n]*)\n') do
      -- Remove carriage return characters (^M)
      line = line:gsub('\r', '')
      table.insert(lines, line)
    end

    -- Handle last line if no trailing newline
    if not formatted_body:match('\n$') then
      local last_line = formatted_body:match('[^\n]+$')
      if last_line then
        table.insert(lines, last_line:gsub('\r', ''))
      end
    end
  end

  return lines
end

-- Format body based on content type
function M.format_body(body, headers, config)
  -- Check if formatting is enabled
  if not config.format_response then
    return body
  end

  -- Detect JSON content type
  local content_type = headers['Content-Type'] or headers['content-type'] or ''
  local is_json = content_type:match('application/json') or content_type:match('application/.*%+json')

  -- Try to detect JSON by content if Content-Type is not set
  if not is_json and body:match('^%s*[%[{]') then
    is_json = true
  end

  -- Format JSON with jq if available
  if is_json then
    return M.format_json_with_jq(body)
  end

  return body
end

-- Format JSON using jq
function M.format_json_with_jq(json_body)
  -- Check if jq is available
  local jq_available = vim.fn.executable('jq') == 1
  if not jq_available then
    return json_body
  end

  -- Use jq to format JSON
  -- Using vim.fn.system to pipe JSON through jq
  local formatted = vim.fn.system('jq .', json_body)

  -- Check if jq succeeded (exit code 0)
  if vim.v.shell_error == 0 then
    return formatted
  else
    -- If jq failed, return original body
    return json_body
  end
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
