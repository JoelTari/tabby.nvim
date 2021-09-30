local tabby = {}

local defaults = require("tabby.defaults")
local component = require("tabby.component")
local render = require("tabby.render")

function tabby.setup()
	if vim.api.nvim_get_vvar("vim_did_enter") then
		tabby.init()
	else
		vim.cmd("au VimEnter * lua require'tabby'.init()")
	end
end

function tabby.init()
	vim.o.showtabline = 2
	vim.o.tabline = "%!TabbyTabline()"
end

function tabby.update()
	local coms = {} ---@see TabbyComponent[]
	local tabs = vim.api.nvim_list_tabpages()
	for _, head_item in ipairs(defaults.head) do
		table.insert(coms, {
			type = "text",
			text = head_item,
		})
	end
	for _, tabid in ipairs(tabs) do
		if tabid == vim.api.nvim_get_current_tabpage() then
			local cfg = defaults.active_tab
			table.insert(coms, render.tab(tabid, cfg))
			local wins = vim.api.nvim_tabpage_list_wins(tabid)
			for _, winid in ipairs(wins) do
				cfg = defaults.active_tab_win
				table.insert(coms, render.active_tab_win(winid, cfg))
			end
		else
			local cfg = defaults.inactive_tab
			table.insert(coms, render.tab(tabid, cfg))
		end
	end
	table.insert(coms, {
		type = "text",
		text = {
			"",
			hl = defaults.hl,
		},
	})
	local tablines = table.concat(vim.tbl_map(component.render, coms))
	return tablines
end

function tabby.handle_buf_click()
	-- function tabby.handle_buf_click(minwid, clicks, button, modifier)
	-- print("buf click: ", minwid, clicks, button, modifier)
end

return tabby