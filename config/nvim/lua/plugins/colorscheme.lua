-- Read theme from ~/.config/omaterm/nvim.theme, default to "default" (terminal ANSI colors)
local theme_file = vim.fn.expand("~/.config/omaterm/nvim.theme")
local theme = "tokyonight"

local ok, lines = pcall(vim.fn.readfile, theme_file)
if ok and #lines > 0 and lines[1]:match("%S") then
	theme = vim.trim(lines[1])
end

local plugins = {
	-- All Omarchy theme plugins (lazy-loaded, only selected one activates)
	{ "ribru17/bamboo.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/aether.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/ethereal.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/hackerman.nvim", lazy = true, priority = 1000 },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },
	{ "sainnhe/everforest", lazy = true, priority = 1000 },
	{ "kepano/flexoki-neovim", lazy = true, priority = 1000 },
	{ "ellisonleao/gruvbox.nvim", lazy = true, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
	{ "tahayvr/matteblack.nvim", lazy = true, priority = 1000 },
	{ "loctvl842/monokai-pro.nvim", lazy = true, priority = 1000 },
	{ "shaunsingh/nord.nvim", lazy = true, priority = 1000 },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000 },
	{ "folke/tokyonight.nvim", lazy = true, priority = 1000 },
	{ "xero/miasma.nvim", lazy = true, priority = 1000 },
}

-- base16 colorscheme engine is desktop-only (loaded by lua/matugen.lua for
-- live SIGUSR1 theme recoloring). Skip on server installs so the plugin is
-- never fetched.
local profile = vim.fn.readfile(vim.fn.expand("~/.config/omaterm/profile"))
if profile and profile[1] == "desktop" then
	table.insert(plugins, { "RRethy/nvim-base16", name = "nvim-base16", lazy = true, priority = 1000 })
end

return vim.list_extend(plugins, {
	-- Apply selected theme
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = theme,
		},
	},
})
