# gemini-cli.nvim

🤖 Seamlessly integrate GeminiCLI with Neovim for an enhanced AI-assisted coding experience!

## 🌟 Features

- [x] 🖥️ Gemini CLI terminal integration within Neovim
- [x] 📤 Quick commands to add current buffer files (using `@` syntax)
- [x] 🩺 Send current buffer diagnostics to Gemini CLI
- [x] 🔍 Gemini CLI command selection UI with fuzzy search and input prompt
- [x] 🔌 Fully documented [Lua API](lua/gemini_cli/api.lua) for
      programmatic interaction and custom integrations
- [x] 🔄 Auto-reload buffers on external changes (requires 'autoread')
- [x] 🐛 **Advanced debug system** with detailed logging and diagnostics
- [x] 🔧 **Multiple file adding methods** with automatic fallback for compatibility
- [x] 📊 **Real-time terminal response analysis** to diagnose communication issues

## 🎮 Commands

- `:Gemini` - Open interactive command menu

  ```text
  Commands:
  health         🩺 Check plugin health status
  toggle         🎛️ Toggle GeminiCLI terminal window
  command        ⌨️ Show slash commands
   > diagnostics 🩺 Send current buffer diagnostics
  add_file       ➕ Add current file to session (using `@` syntax)
  ask            ❓ Ask a question
  debug          🐛 Debug utilities
   > enable      ▶️ Enable debug logging
   > disable     ⏸️ Disable debug logging
   > status      📊 Show debug status
   > clear       🗑️ Clear debug log
   > open        📖 Open debug log file
   > level       🎚️ Set debug level (DEBUG|INFO|WARN|ERROR)
  ```

- ⚡ Direct command execution examples:

  ```vim
  :Gemini health
  :Gemini add_file
  :Gemini send "Fix login validation"
  :Gemini debug enable
  :Gemini debug status
  :GeminiDebug open
  ```

## 🔗 Requirements

🐍 Python: Install `gemini-cli`
📋 System: **Neovim** >= 0.9.4
🌙 Lua: `folke/snacks.nvim`,

## 📦 Installation

Using lazy.nvim:

```lua
{
    "marcinjahn/gemini-cli.nvim",
    cmd = "Gemini",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini CLI" },
      { "<leader>aa", "<cmd>Gemini ask<cr>", desc = "Ask Gemini", mode = { "n", "v" } },
      { "<leader>af", "<cmd>Gemini add_file<cr>", desc = "Add File" },
      { "<leader>ad", "<cmd>GeminiDebug status<cr>", desc = "Debug Status" },
    },
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("gemini_cli").setup({
        -- Enable debug mode for troubleshooting (optional)
        debug = {
          enabled = false,  -- Set to true if you need debugging
          level = "INFO",
        }
      })
    end,
  }
```

After installing, run `:GeminiCLI health` to check if everything is set up correctly.

## ⚙️ Configuration

There is no need to call setup if you don't want to change the default options.

```lua
require("gemini_cli").setup({
  -- Command that executes GeminiCLI
  gemini_cmd = "gemini",
  -- Command line arguments passed to gemini-cli
  args = {
  },
  -- Automatically reload buffers changed by GeminiCLI (requires vim.o.autoread = true)
  auto_reload = false,
  -- Automatically enter insert mode when switching to terminal (default: false)
  auto_insert_mode = false,
  -- Debug configuration
  debug = {
    enabled = false,  -- Enable debug logging
    level = "INFO",   -- Debug level: "DEBUG", "INFO", "WARN", "ERROR"
    file = vim.fn.stdpath("cache") .. "/gemini_cli_debug.log",  -- Log file path
    notify = false,   -- Show debug notifications
  },
  -- snacks.picker.layout.Config configuration
  picker_cfg = {
    preset = "vscode",
  },
  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "GeminiCLI" },
    style = "gemini_cli",
    position = "right",
  },
})
```

## 🐛 Debug & Troubleshooting

### Quick Debug

If file operations aren't working:

```vim
" Enable debug mode
:GeminiDebug enable

" Try the operation
:Gemini add_file

" Check what happened
:GeminiDebug open
```

### Debug Commands

| Command | Description |
|---------|-------------|
| `:GeminiDebug status` | Show current debug status |
| `:GeminiDebug enable` | Enable debug logging |
| `:GeminiDebug disable` | Disable debug logging |
| `:GeminiDebug clear` | Clear debug log file |
| `:GeminiDebug open` | Open debug log in editor |
| `:GeminiDebug level DEBUG` | Set debug level |

### Known Issues & Solutions

#### `@filename` Command Not Working

**Issue**: In Gemini CLI 0.1.13, the `@filename` command may not work in interactive mode.

**Solution**: Use file content sending instead:
```lua
:lua require('gemini_cli').api.add_current_file_content()
```

**Diagnosis**: Enable debug mode to see terminal responses:
```vim
:GeminiDebug enable
:Gemini add_file
-- Check if terminal shows empty response
```

### Debug Configuration

Enable debug logging at startup:

```lua
require("gemini_cli").setup({
  debug = {
    enabled = true,           -- Enable debug logging
    level = "DEBUG",          -- DEBUG|INFO|WARN|ERROR
    file = "path/to/log",     -- Custom log file path
    notify = false,           -- Show debug notifications
  }
})
```

## 📚 API Reference

The plugin provides a structured API for programmatic integration. Access via `require("gemini_cli").api`

### Core Functions

```lua
local api = require("gemini_cli").api
```

#### `health_check()`

Verify plugin health status

```lua
api.health_check()
```

#### `toggle_terminal(opts?)`

Toggle GeminiCLI terminal window

```lua
api.toggle_terminal()
```

---

### Terminal Operations

#### `send_to_terminal(text, opts?)`

Send raw text directly to GeminiCLI

```lua
api.send_to_terminal("Fix the login validation")
```

#### `send_command(command, input?, opts?)`

Execute specific GeminiCLI command

```lua
api.send_command("/commit", "Add error handling")
```

### File Management

#### `add_file(filepath)`

Add specific file to session

```lua
api.add_file("/src/utils.lua")
```

``

#### `add_current_file()`

Add current buffer's file (uses `add_file` internally)

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    api.add_current_file()
  end
})
```

#### `send_diagnostics_with_prompt(opts?)`

Send current buffer's diagnostics with an optional prompt

```lua
api.send_diagnostics_with_prompt()
```

---

### UI Components

#### `open_command_picker(opts?, callback?)`

Interactive command selector with custom handling

```lua
api.open_command_picker(nil, function(picker, item)
  if item.text == "/custom" then
    -- Implement custom command handling
  else
    -- Default behavior
    picker:close()
    api.send_command(item.text)
  end
end)
```

---

### Debug API

Access debug utilities via `require("gemini_cli").debug`:

```lua
local gemini = require("gemini_cli")

-- Control debug logging
gemini.debug.enable()           -- Enable debug mode
gemini.debug.disable()          -- Disable debug mode
gemini.debug.is_enabled()       -- Check if enabled

-- Log management
gemini.debug.clear_log()        -- Clear log file
gemini.debug.open_log()         -- Open log in editor
gemini.debug.get_log_file()     -- Get log file path

-- Configuration
gemini.debug.set_level("DEBUG") -- Set debug level
gemini.debug.status()           -- Show current status
```

### Alternative File Adding Methods

If `@filename` commands don't work with your Gemini CLI version:

```lua
local api = require("gemini_cli").api

-- Method 1: Send file content directly (recommended fallback)
api.add_current_file_content()

-- Method 2: Try /edit command format
api.add_current_file_with_edit()

-- Method 3: Manual file path (copy to clipboard)
print("@" .. vim.fn.expand("%:p"))
```

---

## 🔧 Troubleshooting

### File Commands Not Working

1. **Enable debug mode**: `:GeminiDebug enable`
2. **Try the command**: `:Gemini add_file`
3. **Check the log**: `:GeminiDebug open`
4. **Look for**: Empty terminal responses or error messages
5. **Use fallback**: `:lua require('gemini_cli').api.add_current_file_content()`

### Common Issues

- **Empty terminal response**: Gemini CLI version doesn't support `@filename` in interactive mode
- **File not found**: Check file paths and working directory in debug log
- **Permission errors**: Verify file read permissions
- **Terminal not responding**: Restart terminal with `:Gemini toggle`

### Getting Help

1. **Check plugin health**: `:Gemini health`
2. **Enable debug logging**: `:GeminiDebug enable`
3. **Reproduce the issue**: Try the failing operation
4. **Collect logs**: `:GeminiDebug open` and share relevant entries
5. **Report issues**: Include debug logs and system information

---

This plugin is a Gemini CLI adaptation of [nvim-aider](https://github.com/GeorgesAlkhouri/nvim-aider).
