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
      "marcinjahn/gemini-cli.nvim",
      cmd = {
        "GeminiTerminalToggle",
        "GeminiHealth",
      },
      keys = {
        { "<leader>a/", "<cmd>Gemini toggle<cr>", desc = "Open Gemini" },
        { "<leader>as", "<cmd>Gemini send<cr>", desc = "Send to Gemini", mode = { "n", "v" } },
        { "<leader>ac", "<cmd>Gemini command<cr>", desc = "Send Command To Gemini" },
        { "<leader>ab", "<cmd>Gemini buffer<cr>", desc = "Send Buffer To Gemini" },
        { "<leader>af", "<cmd>Gemini add_file<cr>", desc = "Add File to Gemini" },
      },
      dependencies = {
        "folke/snacks.nvim",
      },
      config = true,
    },
  },
})
