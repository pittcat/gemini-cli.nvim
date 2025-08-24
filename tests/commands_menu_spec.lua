local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("Commands Menu", function()
  local commands_menu
  local api_mock
  local notify_spy
  local picker_mock
  local mock_picker_instance

  before_each(function()
    package.loaded["gemini_cli.commands_menu"] = nil
    package.loaded["gemini_cli.api"] = nil

    -- Mock API module
    api_mock = {
      health_check = stub.new(),
      toggle_terminal = stub.new(),
      send_to_terminal = stub.new(),
      open_command_picker = stub.new(),
      send_buffer_with_prompt = stub.new(),
      add_current_file = stub.new(),
      add_read_only_file = stub.new(),
    }

    package.loaded["gemini_cli.api"] = api_mock
    commands_menu = require("gemini_cli.commands_menu")

    -- Mock picker and notifications
    picker_mock = mock(require("gemini_cli.picker"), true)
    mock_picker_instance = { close = spy.new() }
    picker_mock.create.returns(mock_picker_instance)
    notify_spy = spy.on(vim, "notify")
  end)

  after_each(function()
    mock.revert(picker_mock)
    package.loaded["gemini_cli.commands_menu"] = nil
    package.loaded["gemini_cli.api"] = nil
  end)

  describe("Command Registration", function()
    it("should have all top-level commands", function()
      local expected = {
        "health",
        "toggle",
        "ask",
        "add_file",
      }
      -- Check that the keys match regardless of order
      local expected_set = {}
      for _, v in ipairs(expected) do
        expected_set[v] = true
      end

      local actual_set = {}
      for _, v in ipairs(vim.tbl_keys(commands_menu.commands)) do
        actual_set[v] = true
      end

      assert.same(expected_set, actual_set)
    end)
  end)

  describe("Command Execution", function()
    it("should execute top-level commands", function()
      commands_menu._load_command({ "health" })
      assert.stub(api_mock.health_check).was_called()

      commands_menu._load_command({ "toggle" })
      assert.stub(api_mock.toggle_terminal).was_called()
    end)

    it("should handle invalid commands", function()
      commands_menu._load_command({ "invalid_command" })
      assert.spy(notify_spy).was_called_with("Invalid GeminiCLI command: invalid_command", vim.log.levels.INFO)
    end)
  end)

  describe("Input Handling", function()
    it("should handle ask command with input", function()
      stub(vim.ui, "input", function(_, cb)
        cb("test input")
      end)

      commands_menu._load_command({ "ask", "test input" })
      assert.stub(api_mock.send_to_terminal).was_called_with("test input")
    end)

    it("should handle empty ask input", function()
      stub(vim.ui, "input", function(_, cb)
        cb("")
      end)

      commands_menu._load_command({ "ask" })
      assert.stub(api_mock.send_to_terminal).was_called_with(nil)
    end)
  end)

  describe("Command Menu Structure", function()
    local menu_items
    local commands_menu

    before_each(function()
      commands_menu = require("gemini_cli.commands_menu")

      -- Mock snacks.picker
      package.loaded["snacks.picker"] = function(opts)
        menu_items = opts.items
        return { close = function() end }
      end

      commands_menu._menu()
    end)

    after_each(function()
      package.loaded["snacks.picker"] = nil
    end)

    it("contains all top-level commands", function()
      local expected = { "health", "toggle", "ask", "add_file" }
      local found = {}
      for _, item in ipairs(menu_items) do
        if not item.parent then
          table.insert(found, item.text)
        end
      end

      table.sort(expected)
      table.sort(found)
      assert.same(expected, found)
    end)
  end)
end)
