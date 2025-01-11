local M = {}

--- @param title string
--- @param msg string
--- @param opts table
function M.add(title, msg, opts)
  opts = opts or {}
  local timeout = opts.timeout or 0
  local at_time = opts.at or "now"

  -- os.execute('notify-send "Neovim 通知" "' .. msg .. '"')
  -- os.execute(string.format('notify-send "%s" "%s"', title, msg))
  local notify_command = string.format('notify-send -t %d "%s" "%s"', timeout, title, msg)

  -- 加入 at 命令
  local full_command = string.format('echo \'%s\' | at %s', notify_command, at_time)

  os.execute(full_command)
end

function M.help()
  local buf = vim.api.nvim_create_buf(false, true)
  local table_body = {
    -- header
    string.rep("-", 40),
    "[HELP]",
    string.rep("-", 40),
    'echo \'notify-send "Title" "message"\' | at 22:30 01/11/2025',
    'echo \'notify-send -t 3000 "Title" "message"\' | at 22:30 01/11/2025',
    'at 10:00 01/11/2025',
    'at 08:00',
    'at now + 1 hour',
    'at 08:00 tomorrow',
  }

  local max_width = 0
  for _, line in ipairs(table_body) do
    max_width = math.max(max_width, #line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, table_body)

  local buf_opts = {
    relative = "editor",
    width = max_width + 4,
    height = #table_body + 2,
    col = 10,
    row = 3,
    style = "minimal",
    border = "rounded"
  }
  local ns_id = vim.api.nvim_create_namespace('atq_highlight_label')
  vim.api.nvim_buf_set_extmark(buf,
    ns_id,
    1, -- line
    0, -- col
    {
      end_row = 2,
      hl_group = '@label' -- :highlight
    }
  )

  local win = vim.api.nvim_open_win(buf, true, buf_opts)

  -- keymap
  -- ESC 關閉窗口
  vim.keymap.set("n", "<ESC>", function()
    vim.api.nvim_win_close(win, true)
  end, { noremap = true, silent = true, buffer = buf })
end

return M

