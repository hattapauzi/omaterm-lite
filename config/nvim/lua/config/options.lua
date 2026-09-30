vim.opt.clipboard = "unnamedplus"

-- Server-minimal: remote-plugin providers (node/perl/python3/ruby) are
-- unused by LazyVim defaults. Disabling them silences `:checkhealth
-- vim.provider` without installing npm/pip/gem/cpan bridges.
-- Hatta (desktop) installs the real bridges via install/hatta.sh; to use
-- them there, delete these four lines (or set to 1) after install.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- OSC 52 paste blocks Neovim for up to 10s when the terminal does not
-- answer, or the clipboard is not text. Use wl-copy locally; OSC 52
-- copy-only on SSH, sudo (env_reset drops SSH_TTY), or hosts without wl-clipboard.
local has_wl = vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1
local use_osc52 = vim.env.SSH_TTY ~= nil
	or vim.env.SSH_CLIENT ~= nil
	or vim.env.SUDO_USER ~= nil
	or not has_wl
if use_osc52 then
	local osc52 = require("vim.ui.clipboard.osc52")
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = osc52.copy("+"),
			["*"] = osc52.copy("*"),
		},
		paste = {
			["+"] = function()
				return vim.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"')
			end,
			["*"] = function()
				return vim.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"')
			end,
		},
	}
end
