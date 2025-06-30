-- Type definitions
---@alias CommandCategory "input"|"direct"

---@class Command
---@field value string The command string with prefix
---@field description string Description of the command's function
---@field category CommandCategory The category this command belongs to

-- Constants
---@type string
local COMMAND_PREFIX = "/"

-- Command registry
---@type table<string, Command>
local commands = {
  compress = {
    value = COMMAND_PREFIX .. "compress",
    description = "Replace chat context with a summary to save tokens",
    category = "direct",
  },
  restore = {
    value = COMMAND_PREFIX .. "restore",
    description = "Restores project files to a state before a tool execution (requires --checkpointing)",
    category = "input", -- Can take tool_call_id
  },
}

return commands

