---@class gemini_cli.picker
local M = {}
local config = require("gemini_cli.config")

---Create a picker for GeminiCLI commands
---@param opts? gemini_cli.Config Optional config that will override the base config for this call only
---@param confirm? fun(picker: snacks.Picker, item: table) Callback function when an item is selected
function M.create(opts, confirm)
  opts = vim.tbl_deep_extend("force", config.options, opts or {})
  -- Build items from commands
  local items = {}
  local longest_cmd = 0
  for cmd_name, cmd_data in pairs(require("gemini_cli.commands_slash")) do
    table.insert(items, {
      text = cmd_data.value,
      description = cmd_data.description,
      category = cmd_data.category,
      name = cmd_name,
    })
    longest_cmd = math.max(longest_cmd, #cmd_data.value)
  end
  longest_cmd = longest_cmd + 2

  return require("snacks.picker")({
    items = items,
    layout = opts.picker_cfg,
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { ("%-" .. longest_cmd .. "s"):format(item.text), "Function" }
      ret[#ret + 1] = { " " .. item.description, "Comment" }
      return ret
    end,

    confirm = confirm,
    prompt = "GeminiCLI \\ Commands > ",
  })
end

return M
