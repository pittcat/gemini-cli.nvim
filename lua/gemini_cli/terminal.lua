local M = {}

local anti_flicker = require("gemini_cli.anti_flicker")
local config = require("gemini_cli.config")
local logger = require("gemini_cli.logger")

---@param opts gemini_cli.Config
---@return string
local function create_cmd(opts)
  local cmd = { opts.gemini_cmd }

  -- Add yolo flag if enabled
  if opts.yolo then
    table.insert(cmd, "--yolo")
  end

  -- Add any additional args
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

  -- Set start_insert and auto_insert based on auto_insert_mode config
  opts.start_insert = opts.auto_insert_mode
  opts.auto_insert = opts.auto_insert_mode

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
  logger.debug("M.send called", {
    text_length = text and #text or 0,
    text_preview = text and text:sub(1, 100) or "nil",
    multi_line = multi_line,
    opts = opts,
  })

  multi_line = multi_line == nil and true or multi_line
  opts = vim.tbl_deep_extend("force", config.options, opts or {})

  logger.debug("M.send configuration", {
    final_multi_line = multi_line,
    merged_opts = opts,
  })

  local cmd = create_cmd(opts)
  logger.debug("M.send command created", { cmd = cmd })

  -- Set start_insert and auto_insert based on auto_insert_mode config for consistency
  opts.start_insert = opts.auto_insert_mode
  opts.auto_insert = opts.auto_insert_mode

  local term = require("snacks.terminal").get(cmd, opts)
  if not term then
    logger.error("M.send failed - no terminal instance", { cmd = cmd })
    vim.notify("Please open a GeminiCLI terminal first.", vim.log.levels.INFO)
    return
  end

  logger.debug("M.send terminal instance found", {
    term_exists = term ~= nil,
    buf_valid = term and term:buf_valid() or false,
  })

  -- Setup anti-flicker events if not already done
  if term and opts.fix_display_flicker then
    setup_terminal_events(term, opts)
  end

  if term and term:buf_valid() then
    logger.debug("M.send attempting to get terminal job id", { buf = term.buf })

    local success, chan = pcall(vim.api.nvim_buf_get_var, term.buf, "terminal_job_id")
    if not success then
      logger.error("M.send failed to get terminal_job_id", { error = chan, buf = term.buf })
      vim.notify("Failed to get terminal job ID!", vim.log.levels.ERROR)
      return
    end

    logger.debug("M.send got terminal channel", { chan = chan })

    if chan then
      local send_success, send_error
      if multi_line then
        -- Use bracketed paste sequences
        local bracket_start = "\27[200~"
        local bracket_end = "\27[201~\r"
        local bracketed_text = bracket_start .. text .. bracket_end

        logger.debug("M.send sending multi-line text", {
          bracketed_length = #bracketed_text,
          original_length = #text,
          chan = chan,
        })

        send_success, send_error = pcall(vim.api.nvim_chan_send, chan, bracketed_text)
      else
        text = text:gsub("\n", " ") .. "\n"

        logger.debug("M.send sending single-line text", {
          processed_length = #text,
          chan = chan,
          text_content = text,
          text_bytes = string.format("bytes: %s", table.concat({ string.byte(text, 1, -1) }, ", ")),
        })

        send_success, send_error = pcall(vim.api.nvim_chan_send, chan, text)
      end

      if send_success then
        logger.info("M.send text sent successfully", {
          text_length = #text,
          multi_line = multi_line,
          chan = chan,
        })
      else
        logger.error("M.send failed to send text", {
          error = send_error,
          chan = chan,
          text_length = #text,
        })
        vim.notify("Failed to send text to terminal: " .. tostring(send_error), vim.log.levels.ERROR)
      end
    else
      logger.error("M.send no terminal job found", { buf = term.buf })
      vim.notify("No GeminiCLI terminal job found!", vim.log.levels.ERROR)
    end
  else
    logger.error("M.send terminal buffer invalid", {
      term_exists = term ~= nil,
      buf_valid = term and term:buf_valid() or false,
    })
    vim.notify("Please open a GeminiCLI terminal first.", vim.log.levels.INFO)
  end
end

---Send a command to the terminal
---@param command string GeminiCLI command (e.g. "/help")
---@param text? string Text to send after the command
---@param opts? gemini_cli.Config Optional config that will override the base config for this call only
function M.command(command, text, opts)
  text = text or ""
  local full_command = command .. " " .. text

  logger.debug("M.command called", {
    command = command,
    text = text,
    full_command = full_command,
    multi_line = false,
  })

  -- NOTE: For GeminiCLI commands that shouldn't get a newline (e.g. `/help`)
  M.send(full_command, opts, false)
end

return M
