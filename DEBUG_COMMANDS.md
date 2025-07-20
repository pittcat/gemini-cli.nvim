# 🐛 Debug Commands Usage Guide

## 📋 Available Commands

### Via `:Gemini debug` (Interactive Menu)

```vim
:Gemini debug           " Show debug submenu
:Gemini debug enable    " Enable debug logging  
:Gemini debug disable   " Disable debug logging
:Gemini debug status    " Show current debug status
:Gemini debug clear     " Clear debug log file
:Gemini debug open      " Open debug log in Neovim
:Gemini debug level DEBUG  " Set debug level
```

### Via `:GeminiDebug` (Direct Command)

```vim
:GeminiDebug                 " Show debug status
:GeminiDebug enable          " Enable debug logging
:GeminiDebug disable         " Disable debug logging  
:GeminiDebug status          " Show debug status
:GeminiDebug clear           " Clear debug log
:GeminiDebug open            " Open debug log
:GeminiDebug level DEBUG     " Set debug level
```

### Via Lua API

```lua
local gemini = require('gemini_cli')

-- Enable/disable
gemini.debug.enable()
gemini.debug.disable()

-- Status and control
gemini.debug.status()
gemini.debug.set_level("DEBUG")

-- Log management  
gemini.debug.clear_log()
gemini.debug.open_log()
gemini.debug.get_log_file()

-- Check if enabled
if gemini.debug.is_enabled() then
  print("Debug is enabled")
end
```

## ⚙️ Configuration

### Enable at startup
```lua
require("gemini_cli").setup({
  debug = {
    enabled = true,           -- Enable debug logging
    level = "DEBUG",          -- Set level
    file = "/path/to/debug.log",  -- Custom log file
    notify = false,           -- Show notifications
  }
})
```

### Debug Levels
- `DEBUG`: All messages (most verbose)
- `INFO`: Info, warnings, and errors  
- `WARN`: Warnings and errors only
- `ERROR`: Errors only

## 🎯 Common Usage Patterns

### Quick debugging session
```vim
" Enable debug mode
:GeminiDebug enable

" Try your operation (e.g., add file)
:Gemini add_file

" Check the log
:GeminiDebug open
```

### Persistent debugging
```lua
-- In your config
require("gemini_cli").setup({
  debug = {
    enabled = true,
    level = "DEBUG",
  }
})
```

### Log analysis
```vim
" Check current status
:GeminiDebug status

" Open log file
:GeminiDebug open

" Clear old logs
:GeminiDebug clear

" Set appropriate level
:GeminiDebug level INFO
```

## 📊 Debug Output

The debug log includes:
- Function calls with parameters
- Configuration details
- Terminal communication (byte-level)
- Response analysis
- Error diagnostics

Example log entry:
```
[2025-07-20 14:55:43] [DEBUG] M.send called | {
  multi_line = false,
  text_length = 15,
  text_preview = "@scripts/era.md"
}
```

## 🔧 Troubleshooting

If debug commands don't work:

1. **Reload the plugin**:
   ```vim
   :GeminiDebug status
   ```

2. **Check if logger is available**:
   ```lua
   :lua print(require('gemini_cli.logger'))
   ```

3. **Verify configuration**:
   ```lua
   :lua print(vim.inspect(require('gemini_cli').config.options.debug))
   ```