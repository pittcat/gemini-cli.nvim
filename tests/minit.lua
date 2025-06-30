#!/usr/bin/env -S nvim -l

-- setting this env will override all XDG paths
vim.env.LAZY_STDPATH = ".tests"
-- this will install lazy in your stdpath
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Configure plugins
-- local plugins = {
--   "nvim-lua/plenary.nvim",
-- }

-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    { dir = vim.uv.cwd() },
    "LazyVim/starter",
    {
      "GeorgesAlkhouri/nvim-gemini-cli",
      cmd = {
        "GeminiTerminalToggle",
        "GeminiHealth",
      },
      keys = {
        { "<leader>a/", "<cmd>GeminiCLI toggle<cr>", desc = "Open GeminiCLI" },
        { "<leader>as", "<cmd>GeminiCLI send<cr>", desc = "Send to GeminiCLI", mode = { "n", "v" } },
        { "<leader>ac", "<cmd>GeminiCLI command<cr>", desc = "Send Command To GeminiCLI" },
        { "<leader>ab", "<cmd>GeminiCLI buffer<cr>", desc = "Send Buffer To GeminiCLI" },
        { "<leader>a+", "<cmd>GeminiCLI add_file<cr>", desc = "Add File to GeminiCLI" },
      },
      dependencies = {
        "folke/snacks.nvim",
        --- The below dependencies are optional
        "catppuccin/nvim",
        "nvim-tree/nvim-tree.lua",
        {
          "nvim-neo-tree/neo-tree.nvim",
          opts = function(_, opts)
            require("gemini_cli.neo_tree").setup(opts)
          end,
        },
      },
      config = true,
    },
  },
})
