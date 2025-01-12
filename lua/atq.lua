local M = {}

--- @param title string
--- @param msg string
--- @param opts table
function M.add(title, msg, opts)
  if title == "" or msg == "" then
    vim.notify("缺少title或msg", vim.log.levels.ERROR)
    return
  end

  opts = opts or {}
  local timeout = opts.timeout or 0
  local at_time = opts.at or "now"

  -- os.execute('notify-send "Neovim 通知" "' .. msg .. '"')
  -- os.execute(string.format('notify-send "%s" "%s"', title, msg))
  local notify_command = string.format('notify-send -t %d "%s" "%s"', timeout, title, msg)

  -- 加入 at 命令
  local full_command = string.format('echo \'%s\' | at %s', notify_command, at_time)

  print("Executing command: " .. full_command)
  os.execute(full_command)
end

function M.help()
  local buf = vim.api.nvim_create_buf(false, true)
  local table_body = {
    -- header
    string.rep("-", 40),
    "[HELP]",
    string.rep("-", 40),
    'Atq title body -a 01:08', -- no timeout
    'Atq title body -a 01:08 -t 3000',
    'Atq title body -a "01:18 01/12/2025"',
    'echo \'notify-send "Title" "message"\' | at 22:30 01/11/2025',
    'echo \'notify-send -t 3000 "Title" "message"\' | at 22:30 01/11/2025',
    'at 10:00 01/11/2025',
    'at 08:00',
    'at now + 1 hour',
    'at 08:00 tomorrow',
    '!atq',      -- 查看排程
    '!at -c 11', -- 查看任務編號為11所要做的內容
    'atrm 11',   -- 刪除排程
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

function M.setup()
  vim.api.nvim_create_user_command("Atq",
    function(args)
      -- print(vim.inspect(args.fargs)) --  { "title", "body", "-a", "01:27", "01/12/2025", "-t", "3000" }
      -- print(vim.inspect(args.args)) -- "title body -a 01:27 01/12/2025 -t 3000"
      if #args.fargs < 2 then
        vim.notify("參數至少要2個(title, msg)", vim.log.levels.ERROR)
      end
      local a = args.fargs -- 它是用空白拆分，這會導致如果title或者body有空白有會不正確
      -- local a = vim.split(args.args, " ") -- args.args是一個字串
      -- local a = vim.split(args.args, "%s+") -- 支持空白分隔符
      local title = a[1]
      local msg = a[2]

      if title:sub(1, 1) == "-" or msg:sub(1, 1) == "-" then
        vim.notify("❌ title或者msg不能用`-`開頭", vim.log.levels.ERROR)
        return
      end

      -- 默認不傳值
      local timeout = nil
      local at_time = nil

      -- 可選的 timeout 與 at (例如: `-t 3000`, `-a 22:30`, `-a 22:30 01/12/2025`)
      local begin_opt = false
      for i = 3, #a do
        if not begin_opt and a[i] == "-a" or a[i] == "-t" then
          begin_opt = true
        end

        if a[i] == "-t" and tonumber(a[i + 1]) then
          timeout = tonumber(a[i + 1]) -- 設定 timeout 為整數
        elseif a[i] == "-a" and a[i + 1] then
          if i + 2 > #a or
              (i + 2 <= #a and a[i + 2]:sub(1, 1) == "-") then -- 判別它的下一個參數，如果是-開頭表示為別的可選項
            at_time = a[i + 1]
          else                                                 -- elseif i + 2 <= #a then
            at_time = a[i + 1] .. " " .. a[i + 2]
          end
        else
          if not begin_opt then
            msg = msg .. " " .. a[i] -- 視為msg的沿續
          end
        end
      end

      vim.notify(
        string.format("新增提醒: 標題=%s, 訊息=%s, 超時=%d, 時間=%s",
          title, msg, timeout or 0, at_time or "now")
      )
      M.add(title, msg, { timeout = timeout, at = at_time })
    end,
    {
      nargs = "*",
      desc = "新增提醒",
      complete = function()
        return { -- 自動完成
          "-a 15:04 01/02/2006",
          "-a 15:04",
          -- "-a now + 1 hour", -- 目前不支援
          "-a 08:00 tomorrow",
          "-a 15:04 01/02/2006 -t 6000",
          "-t 8000",
          'title body',
          'title body -a 15:04 01/02/2006 -t 6000',
          'title line1\\nline 2\\nline 3 -a 15:04',
          'title line1\\nline 2\\nline 3 -a 15:04 01/02/2006 -t 6000'
        }
      end,
    }
  )
end

return M
