vim.api.nvim_create_user_command("Gemini", function(opts)
  local commands_menu = require("gemini_cli.commands_menu")

  if #opts.fargs == 0 then
    commands_menu._menu()
  else
    commands_menu._load_command(opts.fargs)
  end
end, {
  desc = "Aider command interface",
  nargs = "*",
  complete = function(arg_lead, line)
    local cmds = require("gemini_cli.commands_menu").commands
    local parts = vim.split(line:gsub("%s+", " "), " ")

    -- Complete subcommands when typing after main command
    if #parts >= 2 then
      local main_cmd = parts[2]
      if cmds[main_cmd] and cmds[main_cmd].subcommands then
        return vim
          .iter(vim.tbl_keys(cmds[main_cmd].subcommands))
          :filter(function(key)
            return key:find(arg_lead) == 1
          end)
          :totable()
      end
    end

    -- Complete main commands
    return vim
      .iter(vim.tbl_keys(cmds))
      :filter(function(key)
        return key:find(arg_lead) == 1
      end)
      :totable()
  end,
})

-- Track which deprecation warnings have been shown
local deprecated_shown = {}

-- Create a wrapper function for deprecated commands
local function create_deprecated_handler(cmd, replacement, handler)
  return function(opts)
    if not deprecated_shown[cmd] then
      vim.notify(
        ("`%s` is deprecated and will be removed in future versions - use `%s` instead"):format(cmd, replacement),
        vim.log.levels.WARN,
        { title = "gemini-cli" }
      )
      deprecated_shown[cmd] = true
    end
    handler(opts)
  end
end

vim.api.nvim_create_user_command(
  "GeminiHealth",
  create_deprecated_handler("GeminiHealth", "Gemini health", function()
    require("gemini_cli.api").health_check()
  end),
  { desc = "Run gemini-cli health check" }
)

vim.api.nvim_create_user_command(
  "GeminiTerminalToggle",
  create_deprecated_handler("GeminiTerminalToggle", "Gemini toggle", function()
    require("gemini_cli.api").toggle_terminal()
  end),
  { desc = "Toggle Gemini terminal" }
)

vim.api.nvim_create_user_command(
  "GeminiTerminalSend",
  create_deprecated_handler("GeminiTerminalSend", "Gemini send", function(args)
    require("gemini_cli.api").send_to_terminal(args.args)
  end),
  { nargs = "?", range = true, desc = "Send text to Gemini terminal" }
)

vim.api.nvim_create_user_command(
  "GeminiQuickSendCommand",
  create_deprecated_handler("GeminiQuickSendCommand", "Gemini command", function()
    require("gemini_cli.api").open_command_picker()
  end),
  { desc = "Send Gemini slash command to Gemini terminal" }
)

vim.api.nvim_create_user_command(
  "GeminiQuickSendBuffer",
  create_deprecated_handler("GeminiQuickSendBuffer", "Gemini buffer", function()
    require("gemini_cli.api").send_buffer_with_prompt()
  end),
  { desc = "Send buffer to Gemini terminal" }
)

vim.api.nvim_create_user_command(
  "GeminiQuickAddFile",
  create_deprecated_handler("GeminiQuickAddFile", "Gemini add", function()
    require("gemini_cli.api").add_current_file()
  end),
  { desc = "Add current file to Gemini session" }
)

vim.api.nvim_create_user_command("GeminiQuickReadOnlyFile",
  create_deprecated_handler("GeminiQuickReadOnlyFile", "Gemini add readonly", function()
    require("gemini_cli.api").add_read_only_file()
  end),
  { desc = "Add current file as read-only to Gemini session" }
)
