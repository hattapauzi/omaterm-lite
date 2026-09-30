-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- matugen live theme recoloring is a desktop-only feature (SIGUSR1 driven
-- by the matugen daemon on Wayland). Only register its signal handler here;
-- do NOT apply the wallpaper-matched theme at startup so fresh installs
-- boot on `base16-default-dark` (see lua/plugins/colorscheme.lua). The daemon's
-- first SIGUSR1 re-applies the wallpaper-matched theme on demand.
local profile = vim.fn.readfile(vim.fn.expand("~/.config/omaterm/profile"))
if profile and profile[1] == "desktop" then
  pcall(require, "matugen")
end
