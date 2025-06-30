local mock = require("luassert.mock")
local gemini_cli = require("gemini_cli")
local spy = require("luassert.spy")

describe("Read-only Commands", function()
  local original_terminal
  local mock_terminal

  before_each(function()
    original_terminal = require("gemini_cli.terminal")
    mock_terminal = mock(original_terminal, true)
    gemini_cli.setup()
  end)

  after_each(function()
    mock.revert(mock_terminal)
    package.loaded["gemini_cli.terminal"] = original_terminal
  end)

  it("sends file with @ prefix when add_read_only_file is called", function()
    -- Create a test buffer and set it as current
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)

    -- Mock the buffer name and ensure it's a normal buffer
    vim.api.nvim_buf_set_name(bufnr, "/fake/git/root/some/file.lua")
    vim.bo[bufnr].buftype = ""

    -- Set up the plugin
    gemini_cli.setup()

    require("gemini_cli.api").add_read_only_file()
    -- Give a small delay for the command to execute
    vim.wait(100)

    -- Verify the terminal send was called correctly
    assert.equals(1, #mock_terminal.send_calls, "Expected one terminal send call")
    assert.equals(
      "@/fake/git/root/some/file.lua",
      mock_terminal.send_calls[1].text,
      string.format("Expected text '%s' but got '%s'", "@/fake/git/root/some/file.lua", mock_terminal.send_calls[1].text)
    )
  end)

  it("shows notification for invalid buffer", function()
    -- Create a terminal buffer
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)

    -- Set buffer type safely
    pcall(function()
      vim.api.nvim_buf_set_option(bufnr, "buftype", "terminal")
    end)

    local notify_spy = spy.on(vim, "notify")

    -- Set up the plugin
    gemini_cli.setup()

    -- Execute the command
    local ok, _ = pcall(function()
      require("gemini_cli.api").add_read_only_file()
    end)
    assert(ok, "Command should execute without error")

    local ok, _ = pcall(function()
      require("gemini_cli.api").add_read_only_file()
    end)
    assert(ok, "Command should execute without error")

    -- Verify notifications
    assert.spy(notify_spy).was_called_with("No valid file in current buffer", vim.log.levels.INFO)
    assert.is_nil(mock_terminal.send_calls, "Expected no terminal sends to be called")
  end)
end)