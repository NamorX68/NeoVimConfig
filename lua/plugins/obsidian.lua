return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "/Users/romanthimian/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault",
      },
    },
        notes_subdir = "Files",
        daily_notes = {
            folder = "Daily"
        },
        templates = {
            subdir = "Templates"
        }
  },
}
