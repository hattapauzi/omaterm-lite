vim.opt.clipboard = "unnamedplus"

-- Remote-plugin providers (node/perl/python3/ruby) are unused by LazyVim
-- defaults. On server/lite they are disabled to silence `:checkhealth
-- vim.provider` without installing npm/pip/gem/cpan bridges. On Hatta
-- (desktop) install/hatta.sh installs the real bridges, so providers stay
-- enabled there — gated on the installer-written flavor file, which is
-- absent when this config is used standalone (defaults to quiet server
-- behaviour).
local _flavor_ok, _flavor_lines = pcall(vim.fn.readfile, vim.fn.expand("~/.config/omaterm/flavor"))
local _flavor = (_flavor_ok and _flavor_lines and _flavor_lines[1]) or ""
if _flavor ~= "hatta" then
  vim.g.loaded_node_provider = 0
  vim.g.loaded_perl_provider = 0
  vim.g.loaded_python3_provider = 0
  vim.g.loaded_ruby_provider = 0
end

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
