# [![gemini-cli](https://avatars.githubusercontent.com/u/172139148?s=20&v=4)](https://gemini-cli.chat) nvim-gemini-cli

🤖 Seamlessly integrate GeminiCLI with Neovim for an enhanced AI-assisted coding experience!

<img width="1280" alt="screenshot_1" src="https://github.com/user-attachments/assets/5d779f73-5441-4d24-8cce-e6dfdc5bf787" />
<img width="1280" alt="screenshot_2" src="https://github.com/user-attachments/assets/3c122846-ca27-42d3-8cbf-f6e5f9b10f69" />

> 🚧 This plugin is in initial development. Expect breaking changes and rough edges.
> _October 17, 2024_

## 🌟 Features

- [x] 🖥️ GeminiCLI terminal integration within Neovim
- [x] 📤 Quick commands to add current buffer files (using `@` syntax)
- [x] 📤 Send buffers or selections to GeminiCLI
- [ ] ♻️ Reset command to clear session (not directly supported by Gemini CLI)
- [x] 💬 Optional user prompt for buffer and selection sends
- [x] 🩺 Send current buffer diagnostics to GeminiCLI
- [x] 🔍 GeminiCLI command selection UI with fuzzy search and input prompt
- [x] 🔌 Fully documented [Lua API](lua/gemini_cli/api.lua) for
      programmatic interaction and custom integrations
- [x] 🔄 Auto-reload buffers on external changes (requires 'autoread')

## 🎮 Commands

- `:GeminiCLI` - Open interactive command menu

  ```text
  Commands:
  health         🩺 Check plugin health status
  toggle         🎛️ Toggle GeminiCLI terminal window
  send           📤 Send text to GeminiCLI (prompt if empty)
  command        ⌨️ Show slash commands
  buffer         📄 Send current buffer
   > diagnostics 🩺 Send current buffer diagnostics
  add_file       ➕ Add current file to session (using `@` syntax)
  ask            ❓ Ask a question
  ```

- ⚡ Direct command execution examples:

  ```vim
  :GeminiCLI health
  :GeminiCLI add_file
  :GeminiCLI send "Fix login validation"
  ```

## 🔗 Requirements

🐍 Python: Install `gemini-cli-chat`
📋 System: **Neovim** >= 0.9.4, ~~Working clipboard~~ thanks to @milanglacier
🌙 Lua: `folke/snacks.nvim`,
_optionals_ `catppuccin/nvim`, `nvim-neo-tree/neo-tree.nvim`, `nvim-tree.lua`

## 📦 Installation

Using lazy.nvim:

```lua
{
    "marcinjahn/gemini-cli.nvim",
    cmd = "Gemini",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini CLI" },
      { "<leader>as", "<cmd>Gemini send<cr>", desc = "Send to Gemini CLI", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>Gemini command<cr>", desc = "Gemini CLI Commands" },
      { "<leader>ab", "<cmd>Gemini buffer<cr>", desc = "Send Buffer" },
      { "<leader>a+", "<cmd>Gemini add_file<cr>", desc = "Add File" },

    },
    dependencies = {
      "folke/snacks.nvim",
      --- The below dependencies are optional
      "catppuccin/nvim",


    },
    config = true,
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

#### `reset_session(opts?)`

Drop all files and clear chat history

```lua
api.reset_session()
```

---

### File Management

#### `add_file(filepath)`

Add specific file to session

```lua
api.add_file("/src/utils.lua")
```

#### `drop_file(filepath)`

Remove file from session

```lua
api.drop_file("/outdated/legacy.py")
```

#### `add_current_file()`

Add current buffer's file (uses `add_file` internally)

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    api.add_current_file()
  end
})
```

#### `drop_current_file()`

Remove current buffer's file

```lua
api.drop_current_file()
```

#### `add_read_only_file()`

Add current buffer as read-only reference

```lua
api.add_read_only_file()
```

---

### Buffer Operations

#### `send_buffer_with_prompt(opts?)`

Send entire buffer content with optional prompt

```lua
api.send_buffer_with_prompt()
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

## 🧩 Other GeminiCLI Neovim plugins

- [gemini-cli.nvim](https://github.com/joshuavial/gemini-cli.nvim)
- [gemini-cli.vim](https://github.com/nekowasabi/gemini-cli.vim)

---

<div align="center">
Made with 🤖 using <a href="https://github.com/paul-gauthier/gemini-cli">GeminiCLI</a>
</div>
