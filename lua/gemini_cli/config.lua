---@alias gemini_cli.Color string

---@class gemini_cli.Theme: table<string, gemini_cli.Color>
---@field user_input_color gemini_cli.Color
---@field tool_output_color gemini_cli.Color
---@field tool_error_color gemini_cli.Color
---@field tool_warning_color gemini_cli.Color
---@field assistant_output_color gemini_cli.Color
---@field completion_menu_color gemini_cli.Color
---@field completion_menu_bg_color gemini_cli.Color
---@field completion_menu_current_color gemini_cli.Color
---@field completion_menu_current_bg_color gemini_cli.Color

---@class gemini_cli.Config: snacks.terminal.Opts
---@field auto_reload? boolean Automatically reload buffers changed by GeminiCLI (requires vim.o.autoread = true)
---@field gemini_cmd? string
---@field args? string[]
---@field theme? gemini_cli.Theme
---@field win? snacks.win.Config
---@field picker_cfg? snacks.picker.layout.Config
local M = {}

M.defaults = {
  auto_reload = false,
  gemini_cmd = "gemini-cli",
  args = {},
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  theme = {
    user_input_color = "#a6da95",
    tool_output_color = "#8aadf4",
    tool_error_color = "#ed8796",
    tool_warning_color = "#eed49f",
    assistant_output_color = "#c6a0f6",
    completion_menu_color = "#cad3f5",
    completion_menu_bg_color = "#24273a",
    completion_menu_current_color = "#181926",
    completion_menu_current_bg_color = "#f4dbd6",
  },
  win = {
    wo = { winbar = "GeminiCLI" },
    style = "gemini_cli",
    position = "right",
  },
  picker_cfg = {
    preset = "vscode",
  },
}

---@type gemini_cli.Config
M.options = vim.deepcopy(M.defaults)

---@param colors table
local function set_catppuccin_colors(colors)
  M.options.theme = {
    user_input_color = colors.green,
    tool_output_color = colors.blue,
    tool_error_color = colors.red,
    tool_warning_color = colors.yellow,
    assistant_output_color = colors.mauve,
    completion_menu_color = colors.text,
    completion_menu_bg_color = colors.base,
    completion_menu_current_color = colors.crust,
    completion_menu_current_bg_color = colors.pink,
  }
end

---@param opts? gemini_cli.Config
function M.setup(opts)
  local ok, _ = pcall(require, "catppuccin.palettes")
  if ok then
    local current_color = vim.g.colors_name
    local flavour = require("catppuccin").flavour or vim.g.catppuccin_flavour

    if current_color and current_color:match("^catppuccin") and flavour then
      local colors = require("catppuccin.palettes").get_palette()
      set_catppuccin_colors(colors)
    end
    -- Store opts in closure for autocmd to access
    local user_opts = opts
    -- NOTE: the new colors are only applied when gemini-cli is restarted
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function(args)
        if args.match:match("^catppuccin") then
          local colors = require("catppuccin.palettes").get_palette()
          set_catppuccin_colors(colors)
          -- Apply user options after setting Catppuccin colors
          M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
        end
      end,
    })
  end

  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
  Snacks.config.style("gemini_cli", {})
  return M.options
end

return M
