local M = {}

local anti_flicker = require("gemini_cli.anti_flicker")
local config = require("gemini_cli.config")

---@param opts gemini_cli.Config
---@return string
local function create_cmd(opts)
  local cmd = { opts.gemini_cmd }
  vim.list_extend(cmd, opts.args or {})
  return table.concat(cmd, " ")
end

--- Setup event handlers for terminal instance
--- @param term_instance table The Snacks terminal instance
--- @param opts gemini_cli.Config Configuration options
local function setup_terminal_events(term_instance, opts)
  if not opts.fix_display_flicker then
    return
  end

  -- Event throttling variables
  local last_buf_enter = 0
  local last_win_enter = 0
  local last_buf_leave = 0
  local event_throttle_ms = 100 -- 100ms throttle for duplicate events

  -- Add throttled event listeners
  term_instance:on("BufEnter", function()
    local now = vim.loop.hrtime() / 1000000
    if now - last_buf_enter > event_throttle_ms then
      last_buf_enter = now

      -- Apply anti-flicker settings on BufEnter
      vim.schedule(function()
        if term_instance.win and vim.api.nvim_win_is_valid(term_instance.win) then
          -- Temporarily disable options that may cause flicker
          pcall(vim.api.nvim_win_set_option, term_instance.win, "cursorline", false)
          pcall(vim.api.nvim_win_set_option, term_instance.win, "number", false)
          pcall(vim.api.nvim_win_set_option, term_instance.win, "relativenumber", false)
        end
      end)
    end
  end, { buf = true })

  term_instance:on("WinEnter", function()
    local now = vim.loop.hrtime() / 1000000
    if now - last_win_enter > event_throttle_ms then
      last_win_enter = now

      -- Start anti-flicker mode on window enter
      local time_since_last_leave = now - last_buf_leave
      if time_since_last_leave < 500 then -- 500ms threshold for rapid switching
        anti_flicker.handle_rapid_switching()
      else
        anti_flicker.start_temporary_anti_flicker(150)
      end

      -- Optimize terminal window
      anti_flicker.optimize_terminal_window(term_instance.win, term_instance.buf)
    end
  end, { buf = true })

  term_instance:on("BufLeave", function()
    local now = vim.loop.hrtime() / 1000000
    if now - last_buf_leave > event_throttle_ms then
      last_buf_leave = now
    end
  end, { buf = true })
end

---Toggle terminal visibility
---@param opts? gemini_cli.Config Optional config that will override the base config for this call only
---@return snacks.win?
function M.toggle(opts)
  local snacks = require("snacks.terminal")

  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = snacks.toggle(cmd, opts)

  -- Setup anti-flicker events if enabled
  if term and opts.fix_display_flicker then
    setup_terminal_events(term, opts)
  end

  return term
end

---Send text to terminal
---@param text string Text to send
---@param opts? gemini_cli.Config Optional config that will override the base config for this call only
---@param multi_line? boolean Whether to send as multi-line text (default: true)
function M.send(text, opts, multi_line)
  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  local cmd = create_cmd(opts)
  local term = require("snacks.terminal").get(cmd, opts)
  if not term then
    vim.notify("Please open a GeminiCLI terminal first.", vim.log.levels.INFO)
    return
  end

  -- Setup anti-flicker events if not already done
  if term and opts.fix_display_flicker then
    setup_terminal_events(term, opts)
  end

  if term and term:buf_valid() then
    local chan = vim.api.nvim_buf_get_var(term.buf, "terminal_job_id")
    if chan then
      if multi_line then
        -- Use bracketed paste sequences
        local bracket_start = "\27[200~"
        local bracket_end = "\27[201~\r"
        local bracketed_text = bracket_start .. text .. bracket_end
        vim.api.nvim_chan_send(chan, bracketed_text)
      else
        text = text:gsub("\n", " ") .. "\n"
        vim.api.nvim_chan_send(chan, text)
      end
    else
      vim.notify("No GeminiCLI terminal job found!", vim.log.levels.ERROR)
    end
  else
    vim.notify("Please open a GeminiCLI terminal first.", vim.log.levels.INFO)
  end
end

---Send a command to the terminal
---@param command string GeminiCLI command (e.g. "/help")
---@param text? string Text to send after the command
---@param opts? gemini_cli.Config Optional config that will override the base config for this call only
function M.command(command, text, opts)
  text = text or ""

  -- NOTE: For GeminiCLI commands that shouldn't get a newline (e.g. `/help`)
  M.send(command .. " " .. text, opts, false)
end

return M
