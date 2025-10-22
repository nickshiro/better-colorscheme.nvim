local M = {}

local config_path = vim.fn.stdpath("data") .. "/better-colorscheme.txt"

local function set_theme(theme)
	local ok, err = pcall(vim.cmd.colorscheme, theme)
	if not ok then
		vim.notify("Failed to set colorscheme: " .. err, vim.log.levels.ERROR)
		return
	end
	vim.fn.writefile({ theme }, config_path)
end

local function load_theme()
	local ok, theme = pcall(vim.fn.readfile, config_path)
	if ok and theme[1] then
		local ok_load = pcall(vim.cmd.colorscheme, theme[1])
		if not ok_load then
			vim.notify("Could not load saved theme: " .. theme, vim.log.levels.WARN)
		end
	end
end

local saved = nil
local autocommand_id = nil

local function preview_theme(arg_lead, _, _)
	local colors = vim.fn.getcompletion(arg_lead, "color")

	autocommand_id = vim.api.nvim_create_autocmd({ "CmdlineChanged", "CmdlineLeave" }, {
		desc = "Preview colorscheme during :Colorscheme, restore if aborted",
		callback = function(ev)
			local ok, parsed = pcall(vim.api.nvim_parse_cmd, vim.fn.getcmdline(), {})
			if not ok or parsed.cmd ~= "Colorscheme" or #parsed.args ~= 1 then
				return
			end
			local colorscheme = parsed.args[1]
			if not saved then
				saved = vim.g.colors_name or "default"
			end
			if ev.event == "CmdlineLeave" then
				if vim.v.event.abort then
					colorscheme = saved
				end
				saved = nil
			end
			if not pcall(vim.cmd.colorscheme, colorscheme) then
				vim.cmd.colorscheme(saved)
			end
			vim.cmd.redraw()
		end,
	})

	return colors
end

local function command_handler(opts)
	set_theme(opts.args)

	if autocommand_id then
		vim.api.nvim_del_autocmd(autocommand_id)
	end
end

function M.setup()
	load_theme()

	vim.api.nvim_create_user_command("Colorscheme", command_handler, {
		complete = preview_theme,
		nargs = 1,
		desc = "Set and persist Neovim colorscheme with live preview",
	})
end

return M
