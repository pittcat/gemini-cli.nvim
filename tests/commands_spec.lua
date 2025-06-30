local _, gemini_cli = pcall(require, "gemini_cli")

describe("Command Setup", function()
  before_each(function()
    package.loaded["gemini_cli"] = nil
    gemini_cli = require("gemini_cli")
    gemini_cli.setup() -- Ensure setup is called before tests
  end)

  after_each(function()
    -- Only delete commands created by gemini_cli
    local commands_to_delete = {
      "Gemini",
      "GeminiHealth",
      "GeminiTerminalToggle",
      "GeminiTerminalSend",
      "GeminiQuickSendCommand",
      "GeminiQuickSendBuffer",
      "GeminiQuickAddFile",
      "GeminiQuickReadOnlyFile",
      "GeminiTreeAddReadOnlyFile",
      "GeminiTreeAddFile",
      "GeminiTreeDropFile",
    }
    for _, cmd_name in ipairs(commands_to_delete) do
      pcall(vim.api.nvim_del_user_command, cmd_name)
    end
  end)


  it("executes health check without error", function()
    local health_check_ok = pcall(function() gemini_cli.api.health_check() end)
    assert(health_check_ok, "health_check() should execute without error")
  end)
end)