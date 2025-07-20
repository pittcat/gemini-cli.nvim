local M = {}

local log_levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

local log_level_names = {
  [log_levels.DEBUG] = "DEBUG",
  [log_levels.INFO] = "INFO",
  [log_levels.WARN] = "WARN",
  [log_levels.ERROR] = "ERROR",
}

local current_log_level = log_levels.INFO
local log_file = nil
local log_to_file = false
local log_to_notify = false

function M.setup(opts)
  opts = opts or {}

  if opts.level then
    current_log_level = log_levels[opts.level:upper()] or log_levels.INFO
  end

  if opts.file then
    log_file = vim.fn.expand(opts.file)
    log_to_file = true

    -- 确保日志目录存在
    local log_dir = vim.fn.fnamemodify(log_file, ":h")
    vim.fn.mkdir(log_dir, "p")
  end

  log_to_notify = opts.notify or false
end

local function format_log(level, msg, data)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local level_name = log_level_names[level]
  local formatted = string.format("[%s] [%s] %s", timestamp, level_name, msg)

  if data then
    formatted = formatted .. " | " .. vim.inspect(data)
  end

  return formatted
end

local function write_to_file(message)
  if not log_to_file or not log_file then
    return
  end

  local file = io.open(log_file, "a")
  if file then
    file:write(message .. "\n")
    file:close()
  end
end

local function log(level, msg, data)
  if level < current_log_level then
    return
  end

  local formatted = format_log(level, msg, data)

  -- 写入文件
  write_to_file(formatted)

  -- 发送通知
  if log_to_notify then
    local vim_level = vim.log.levels.INFO
    if level == log_levels.ERROR then
      vim_level = vim.log.levels.ERROR
    elseif level == log_levels.WARN then
      vim_level = vim.log.levels.WARN
    end

    vim.notify(formatted, vim_level, { title = "GeminiCLI" })
  end
end

function M.debug(msg, data)
  log(log_levels.DEBUG, msg, data)
end

function M.info(msg, data)
  log(log_levels.INFO, msg, data)
end

function M.warn(msg, data)
  log(log_levels.WARN, msg, data)
end

function M.error(msg, data)
  log(log_levels.ERROR, msg, data)
end

-- 辅助函数：记录函数调用
function M.trace_function(func_name, args)
  M.debug("Function called: " .. func_name, args)
end

-- 辅助函数：记录函数结果
function M.trace_result(func_name, result, error)
  if error then
    M.error("Function error: " .. func_name, { error = error })
  else
    M.debug("Function result: " .. func_name, { result = result })
  end
end

-- 获取日志文件路径
function M.get_log_file()
  return log_file
end

-- 清空日志文件
function M.clear()
  if log_file then
    local file = io.open(log_file, "w")
    if file then
      file:close()
      M.info("Log file cleared")
    end
  end
end

-- 打开日志文件
function M.open()
  if log_file and vim.fn.filereadable(log_file) == 1 then
    vim.cmd("edit " .. log_file)
  else
    vim.notify("No log file configured or file doesn't exist", vim.log.levels.WARN)
  end
end

return M
