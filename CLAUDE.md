# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin that integrates GeminiCLI with Neovim, providing seamless AI-assisted coding experience. The plugin is written in Lua and uses the `snacks.nvim` framework for terminal and picker functionality.

## Development Commands

### Testing
- `nvim -l tests/minit.lua --minitest` - Run all tests using the minitest framework
- `./scripts/test` - Install gemini-cli and run tests (also installs dependencies)

### Code Formatting
- `stylua .` - Format all Lua files according to stylua.toml configuration
- Configuration: 2-space indentation, 120 column width, sorted requires

### Health Check
- `:checkhealth gemini_cli` - Check plugin health and dependencies from within Neovim

## Architecture

### Core Structure
- `lua/gemini_cli/init.lua` - Main entry point, exports config and api modules
- `lua/gemini_cli/config.lua` - Configuration management with defaults
- `lua/gemini_cli/api.lua` - Public API functions for programmatic access
- `plugin/gemini_cli.lua` - Plugin registration and command definitions

### Key Components
- `terminal.lua` - Terminal integration using snacks.terminal, handles gemini CLI communication
- `picker.lua` - Command picker UI using snacks.picker with fuzzy search
- `commands_slash.lua` - Slash command definitions and metadata
- `commands_menu.lua` - Interactive command menu implementation
- `diagnostics.lua` - LSP diagnostics formatting and handling
- `utils.lua` - Utility functions for file operations

### Dependencies
- `folke/snacks.nvim` - Core dependency for terminal and picker functionality
- `gemini-cli` - External Python CLI tool (installed via curl script)
- Neovim >= 0.9.4

### Plugin Configuration
The plugin uses a configuration system that extends snacks.terminal.Opts:
- `gemini_cmd`: Command to execute (default: "gemini")
- `auto_reload`: Auto-reload buffers on external changes
- `picker_cfg`: snacks.picker configuration
- `win`: Terminal window configuration

### API Design
Public API is exposed through `require("gemini_cli").api` with functions for:
- Terminal operations (toggle, send text/commands)
- File management (add files to session)
- Diagnostics integration
- UI components (command picker)

### Terminal Communication
Uses bracketed paste sequences for multi-line text and direct channel communication for single-line commands. Integrates with nvim-remote for file editing.

## Testing Structure
- Tests use a custom minitest framework
- Test files follow `*_spec.lua` naming convention
- `minit.lua` provides test runner configuration
- Tests cover API methods, commands, terminal operations, and auto-reload functionality