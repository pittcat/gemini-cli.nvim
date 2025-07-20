local M = {}
local commands = require("gemini_cli.commands_slash")
local diagnostics = require("gemini_cli.diagnostics")
local picker = require("gemini_cli.picker")
local terminal = require("gemini_cli.terminal")
local utils = require("gemini_cli.utils")
local logger = require("gemini_cli.logger")

---Run health check
function M.health_check()
  vim.cmd([[
checkhealth gemini_cli
]])
end

---Toggle gemini terminal
---@param opts? table Optional configuration override
function M.toggle_terminal(opts)
  terminal.toggle(opts or {})
end

---Send text to gemini terminal
---@param text? string Optional text to send (nil for visual selection/mode-based handling)
---@param opts? table Optional configuration override
function M.send_to_terminal(text, opts)
  local mode = vim.fn.mode()
  local selected_text = text or ""
  -- Visual mode handling
  if vim.tbl_contains({ "v", "V", "" }, mode) then
    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    selected_text = table.concat(lines, "\n")

    vim.ui.input({ prompt = "Add a prompt to your selection (empty to skip):" }, function(input)
      if input ~= nil then
        if input ~= "" then
          selected_text = selected_text .. "\n> " .. input
        end
        terminal.send(selected_text, opts or {}, true)
      end
    end)
  else
    -- Normal mode handling
    if selected_text == "" then
      vim.ui.input({ prompt = "Send to Gemini: " }, function(input)
        if input then
          terminal.send(input, opts or {})
        end
      end)
    else
      terminal.send(selected_text, opts or {})
    end
  end
end

---Send command to gemini terminal
---@param command string Gemini command to execute
---@param input? string Additional input for the command
---@param opts? table Optional configuration override
function M.send_command(command, input, opts)
  terminal.command(command, input, opts or {})
end

---Send buffer contents with optional prompt
---@param opts? table Optional configuration override
function M.send_buffer_with_prompt(opts)
  local selected_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local file_type = vim.bo.filetype
  file_type = file_type == "" and "text" or file_type

  vim.ui.input({ prompt = "Add a prompt to your buffer (empty to skip):" }, function(input)
    if input ~= nil then
      if input ~= "" then
        selected_text = selected_text .. "\n> " .. input
      end
      terminal.send(selected_text, opts or {}, true)
    end
  end)
end

---Send diagnostics content with optional prompt
---@param opts? table Optional configuration override
function M.send_diagnostics_with_prompt(opts)
  local current_diagnostics = vim.diagnostic.get(0) -- Get diagnostics for the current buffer (bufnr 0)

  if not current_diagnostics or #current_diagnostics == 0 then
    vim.notify("No diagnostics found in the current buffer.", vim.log.levels.INFO)
    return
  end

  local formatted_diagnostics = diagnostics.format_diagnostics(current_diagnostics)
  local buf_name = vim.fn.bufname("%")

  vim.ui.input({
    prompt = "Add a prompt for the diagnostics:",
    default = "Here are the diagnostics for " .. buf_name .. ":",
  }, function(input)
    if input ~= nil then
      local final_output = formatted_diagnostics
      if input ~= "" then
        final_output = input .. "\n" .. final_output
      end
      terminal.send(final_output, opts or {}, true)
    end
  end)
end

---Add specific file to session using @<filepath>
---@param filepath string Path to file to add
---@param opts? table Optional configuration override
function M.add_file(filepath, opts)
  logger.debug("M.add_file called", {
    filepath = filepath,
    opts = opts
  })

  if filepath then
    -- 计算相对路径和绝对路径
    local absolute_path = vim.fn.fnamemodify(filepath, ":p")
    local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
    local current_dir = vim.fn.getcwd()
    
    -- 优先使用相对路径，如果文件在当前工作目录下
    local use_relative = vim.startswith(absolute_path, current_dir)
    local final_path = use_relative and relative_path or absolute_path
    
    -- 使用 @filename 命令（这是正确的方式）
    local file_command = "@" .. final_path
    
    logger.info("M.add_file sending file command", {
      filepath = filepath,
      absolute_path = absolute_path,
      relative_path = relative_path,
      current_working_dir = current_dir,
      use_relative = use_relative,
      final_path = final_path,
      command = file_command,
      file_exists = vim.fn.filereadable(absolute_path) == 1,
      multi_line = false -- 明确标记为单行模式
    })
    
    -- 发送 @filename 命令
    terminal.send(file_command, opts or {}, false) -- 明确指定为单行模式
    
    -- 检查terminal的响应
    vim.defer_fn(function()
      M.check_terminal_response(opts)
    end, 2000)
  else
    logger.error("M.add_file no file path provided")
    vim.notify("No file path provided", vim.log.levels.ERROR)
  end
end

---Add current file to session using @<filepath>
---@param opts? table Optional configuration override
function M.add_current_file(opts)
  logger.debug("M.add_current_file called", { opts = opts })
  
  local filepath = utils.get_absolute_path()
  logger.debug("M.add_current_file got filepath", { filepath = filepath })
  
  if filepath then
    logger.info("M.add_current_file adding current file", { filepath = filepath })
    M.add_file(filepath, opts)
  else
    logger.warn("M.add_current_file no valid file in current buffer")
    vim.notify("No valid file in current buffer", vim.log.levels.INFO)
  end
end

---Add current file using /edit command instead of @
---@param opts? table Optional configuration override
function M.add_current_file_with_edit(opts)
  opts = opts or {}
  opts.use_edit_command = true
  M.add_current_file(opts)
end

---Send file content directly (fallback method)
---@param opts? table Optional configuration override
function M.add_current_file_content(opts)
  logger.debug("M.add_current_file_content called", { opts = opts })
  
  local filepath = utils.get_absolute_path()
  if not filepath then
    logger.warn("M.add_current_file_content no valid file in current buffer")
    vim.notify("No valid file in current buffer", vim.log.levels.INFO)
    return
  end
  
  -- 读取文件内容
  local success, content = pcall(vim.fn.readfile, filepath)
  if not success then
    logger.error("M.add_current_file_content failed to read file", { 
      filepath = filepath, 
      error = content 
    })
    vim.notify("Failed to read file: " .. filepath, vim.log.levels.ERROR)
    return
  end
  
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local relative_path = vim.fn.fnamemodify(filepath, ":.")
  
  -- 构建发送的文本
  local text = string.format("Here's the content of %s:\n\n```%s\n%s\n```", 
    relative_path,
    vim.fn.fnamemodify(filepath, ":e"), -- 文件扩展名
    table.concat(content, "\n")
  )
  
  logger.info("M.add_current_file_content sending file content", {
    filepath = filepath,
    filename = filename,
    relative_path = relative_path,
    content_lines = #content,
    text_length = #text
  })
  
  -- 发送文件内容（多行模式）
  terminal.send(text, opts or {}, true)
  
  -- 检查terminal响应
  vim.defer_fn(function()
    M.check_terminal_response(opts)
  end, 3000) -- 等待3秒后检查响应
end

---Check terminal response after sending command
---@param opts? table Optional configuration override
function M.check_terminal_response(opts)
  local config = require("gemini_cli.config")
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  
  local cmd = opts.gemini_cmd
  local term = require("snacks.terminal").get(cmd, opts)
  
  if not term or not term:buf_valid() then
    logger.error("M.check_terminal_response no valid terminal")
    return
  end
  
  -- 读取terminal buffer的最后几行
  local lines = vim.api.nvim_buf_get_lines(term.buf, -10, -1, false)
  local recent_output = table.concat(lines, "\n")
  
  logger.info("M.check_terminal_response terminal output", {
    lines_count = #lines,
    recent_output = recent_output,
    last_5_lines = vim.list_slice(lines, math.max(1, #lines - 4))
  })
  
  -- 检查是否有错误消息或成功标志
  local has_error = false
  local has_success = false
  local has_file_content = false
  
  for _, line in ipairs(lines) do
    local lower_line = line:lower()
    if lower_line:match("error") or lower_line:match("not found") or lower_line:match("invalid") or 
       lower_line:match("cannot") or lower_line:match("failed") then
      has_error = true
    end
    if lower_line:match("loaded") or lower_line:match("reading") or lower_line:match("analyzing") or
       lower_line:match("file") or lower_line:match("added") then
      has_success = true
    end
    -- 检查是否有文件内容的迹象
    if line:match("```") or line:match("def ") or line:match("function") or 
       line:match("class ") or line:match("#") then
      has_file_content = true
    end
  end
  
  logger.info("M.check_terminal_response analysis", {
    has_error = has_error,
    has_success = has_success,
    has_file_content = has_file_content,
    output_length = #recent_output,
    line_count = #lines
  })
  
  if has_error then
    vim.notify("❌ File command failed - check terminal for errors", vim.log.levels.ERROR)
  elseif has_file_content then
    vim.notify("✅ File content detected in terminal - command appears successful", vim.log.levels.INFO)
  elseif has_success then
    vim.notify("✅ File appears to be loading successfully", vim.log.levels.INFO)
  elseif #recent_output == 0 or #lines <= 1 then
    vim.notify("⚠️  @filename command not supported. Try: :lua require('gemini_cli').api.add_current_file_content()", vim.log.levels.WARN)
  else
    vim.notify("🤔 Terminal has output but unclear if file was loaded - check manually", vim.log.levels.INFO)
  end
end

---Open command picker
---@param opts? table Optional configuration override
---@param callback? function Custom callback handler
function M.open_command_picker(opts, callback)
  picker.create(opts, callback or function(picker_instance, item)
    if item.category == "input" then
      vim.ui.input({ prompt = "Enter input for `" .. item.text .. "` (empty to skip):" }, function(input)
        if input then
          terminal.command(item.text, input, opts)
        end
      end)
    else
      terminal.command(item.text, nil, opts)
    end
    picker_instance:close()
  end)
end

return M

