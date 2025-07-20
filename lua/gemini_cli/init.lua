local M = {}

M.config = require("gemini_cli.config")
M.api = require("gemini_cli.api")
local logger = require("gemini_cli.logger")

-- 添加debug相关的API
M.debug = {
  is_enabled = function() return M.config.options.debug.enabled end,
  enable = function() 
    M.config.options.debug.enabled = true
    logger.setup({
      level = M.config.options.debug.level,
      file = M.config.options.debug.file,
      notify = M.config.options.debug.notify
    })
    vim.notify("Debug logging enabled", vim.log.levels.INFO)
  end,
  disable = function() 
    M.config.options.debug.enabled = false
    vim.notify("Debug logging disabled", vim.log.levels.INFO)
  end,
  set_level = function(level)
    M.config.options.debug.level = level
    if M.config.options.debug.enabled then
      logger.setup({
        level = level,
        file = M.config.options.debug.file,
        notify = M.config.options.debug.notify
      })
    end
    vim.notify("Debug level set to: " .. level, vim.log.levels.INFO)
  end,
  open_log = function() logger.open() end,
  clear_log = function() logger.clear() end,
  get_log_file = function() return logger.get_log_file() end,
  status = function()
    local status = {
      enabled = M.config.options.debug.enabled,
      level = M.config.options.debug.level,
      file = M.config.options.debug.file,
      notify = M.config.options.debug.notify
    }
    print("Debug Status:")
    print("  Enabled: " .. tostring(status.enabled))
    print("  Level: " .. status.level)
    print("  File: " .. status.file)
    print("  Notify: " .. tostring(status.notify))
    return status
  end
}

local deprecation_shown = false

setmetatable(M, {
  __index = function(tbl, key)
    if key == "terminal" then
      if not deprecation_shown then
        vim.notify(
          "[gemini_cli] 'gemini_cli.terminal' is deprecated and will be removed in a future release. Please use 'gemini_cli.api' instead.",
          vim.log.levels.WARN
        )
        deprecation_shown = true
      end
      return require("gemini_cli.terminal")
    end

    return rawget(tbl, key)
  end,
})

---@param opts? nvim_aider.Config
function M.setup(opts)
  -- 先设置基本配置
  M.config.setup(opts)
  
  -- 根据配置初始化logger
  if M.config.options.debug.enabled then
    logger.setup({
      level = M.config.options.debug.level,
      file = M.config.options.debug.file,
      notify = M.config.options.debug.notify
    })
    logger.info("GeminiCLI plugin setup started", { opts = opts })
  end

  if M.config.options.auto_reload then
    if not vim.o.autoread then
      vim.notify_once(
        "gemini-cli: auto-reload disabled because the 'autoread' option is off.\n"
          .. "Run  :set autoread  (or add it to your init) to enable live-reload, "
          .. "or set  require('gemini_cli').setup{ auto_reload = false }  to silence this notice.",
        vim.log.levels.WARN,
        { title = "gemini-cli" }
      )
    else
      -- Autocommand group to avoid stacking duplicates on reload
      local grp = vim.api.nvim_create_augroup("GeminiAutoRefresh", { clear = true })

      -- Trigger :checktime on the events that matter
      vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" }, {
        group = grp,
        pattern = "*",
        callback = function()
          -- Don’t interfere while editing a command line or in terminal‑insert mode
          if vim.fn.mode():match("[ciR!t]") == nil and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
          end
        end,
        desc = "Reload buffer if the underlying file was changed by GeminiCLI or anything else",
      })
    end
  end
end

return M
