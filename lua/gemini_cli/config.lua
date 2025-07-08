---@class gemini_cli.Config: snacks.terminal.Opts
---@field auto_reload? boolean Automatically reload buffers changed by GeminiCLI (requires vim.o.autoread = true)
---@field gemini_cmd? string
---@field args? string[]
---@field win? snacks.win.Config
---@field picker_cfg? snacks.picker.layout.Config
---@field fix_display_flicker? boolean Fix terminal window switching flicker (default: true)
local M = {}

M.defaults = {
  auto_reload = false,
  gemini_cmd = "gemini",
  args = {},
  fix_display_flicker = true,
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "Gemini" },
    style = "gemini_cli",
    position = "right",
  },
  picker_cfg = {
    preset = "vscode",
  },
}

---@type gemini_cli.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? gemini_cli.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
  Snacks.config.style("gemini_cli", {})
  return M.options
end

return M
