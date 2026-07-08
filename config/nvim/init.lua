-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- matugen live theme recoloring is a desktop-only feature (SIGUSR1 driven
-- by the matugen daemon on Wayland). Skip on server installs.
local profile = vim.fn.readfile(vim.fn.expand("~/.config/omaterm/profile"))
if profile and profile[1] == "desktop" then
  local ok, matugen = pcall(require, "matugen")
  if ok then matugen.setup() end
end
