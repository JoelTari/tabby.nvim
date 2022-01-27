local util = require('tabby.util')
local component = require('tabby.component')

--- render TabbyTablineOpt
local tabline = {}

---@class TabbyTablineOpt
---@field layout TabbyTablineLayout
---@field hl TabbyHighlight background highlight
---@field head? TabbyText[] display at start of tabline
---@field active_tab TabbyTabLabelOpt
---@field inactive_tab TabbyTabLabelOpt
---@field win TabbyWinLabelOpt
---@field active_win? TabbyWinLabelOpt need by "tab_with_top_win", fallback to win if this is nil
---@field top_win? TabbyWinLabelOpt need by "active_tab_with_wins" and "active_wins_at_end", fallback to win if this is nil
---@field tail? TabbyText[] display at end of tabline

---@class TabbyTabLabelOpt
---@field label TabbyTabProvider|TabbyTabProvider[]
---@field join string join tab providers
---@field left_sep string|TabbyText
---@field right_sep string|TabbyText

---@alias TabbyTabProviderFn fun(tabid:number):string|TabbyText
---@alias TabbyTabProvider string|TabbyText|TabbyTabProviderFn

---@param tabid number tab id
---@param opt TabbyTabLabelOpt
---@return TabbyComTab
function tabline.render_tab_label(tabid, opt)
  local label
  if type(opt.label) == 'string' then
    label = opt.label
  elseif type(opt.label) == 'table' then
    if vim.tbl_islist(opt.label) then
      local labels = {}
      for _, p in ipairs(opt.label) do
        if type(p) == 'function' then
          labels[#labels + 1] = p(tabid)
        else
          labels[#labels + 1] = p
        end
      end
      label = table.concat(labels)
    else
      label = opt.label
    end
  elseif type(opt.label) == 'function' then
    label = opt.label(tabid)
  end
  return {
    type = 'tab',
    tabid = tabid,
    label = label,
    left_sep = opt.left_sep,
    right_sep = opt.right_sep,
  }
end

---@alias TabbyTablineLayout
---| "active_wins_at_tail" # windows in active tab will be display at end of tabline
---| "active_wins_at_end" # windows in active tab will be display at end of all tab labels
---| "tab_with_top_win"  # the top window display after each tab.
---| "active_tab_with_wins" # windows label follow active tab
---| "tab_only" # no windows label, only tab

---@class TabbyWinLabelOpt
---@field label string|TabbyText|fun(winid:number):TabbyText
---@field left_sep string|TabbyText
---@field inner_sep string|TabbyText won't works in "tab_with_top_win" layout
---@field right_sep string|TabbyText

---@param winid number window id
---@param is_first boolean
---@param is_last boolean
---@param opt TabbyWinLabelOpt
---@return TabbyComWin
function tabline.render_win_label(winid, is_first, is_last, opt)
  local label = opt.label
  if type(opt.label) == 'function' then
    label = opt.label(winid)
  end
  local left_sep = opt.inner_sep or opt.left_sep
  local right_sep = opt.inner_sep or opt.right_sep
  if is_first then
    left_sep = opt.left_sep
  end
  if is_last then
    right_sep = opt.right_sep
  end
  return {
    type = 'win',
    winid = winid,
    label = label,
    left_sep = left_sep,
    right_sep = right_sep,
  }
end

---@param opt TabbyTablineOpt
---@return string statusline-format text
function tabline.render(opt)
  ---@type TabbyComponent[]
  local coms = {}
  -- head
  if opt.head then
    for _, head_item in ipairs(opt.head) do
      table.insert(coms, { type = 'text', text = head_item })
    end
  end
  -- tabs and wins
  local tabs = vim.api.nvim_list_tabpages()
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, tabid in ipairs(tabs) do
    if tabid == current_tab then
      table.insert(coms, tabline.render_tab_label(tabid, opt.active_tab))
      if opt.layout == 'active_tab_with_wins' then
        local wins = util.tabpage_list_wins(current_tab)
        local top_win = vim.api.nvim_tabpage_get_win(current_tab)
        for i, winid in ipairs(wins) do
          local win_opt = opt.win
          if winid == top_win and opt.top_win ~= nil then
            win_opt = opt.top_win
          end
          table.insert(coms, tabline.render_win_label(winid, i == 1, i == #wins, win_opt))
        end
      end
    else
      table.insert(coms, tabline.render_tab_label(tabid, opt.inactive_tab))
    end
    if opt.layout == 'tab_with_top_win' then
      local win_opt = opt.win
      if tabid == current_tab and opt.active_win then
        win_opt = opt.active_win
      end
      local winid = vim.api.nvim_tabpage_get_win(tabid)
      table.insert(coms, tabline.render_win_label(winid, true, true, win_opt))
    end
  end
  if opt.layout == 'active_wins_at_end' or opt.layout == 'active_wins_at_tail' then
    if opt.layout == 'active_wins_at_tail' then
      table.insert(coms, { type = 'text', text = { '%=', hl = opt.hl } })
    end
    local wins = util.tabpage_list_wins(current_tab)
    local top_win = vim.api.nvim_tabpage_get_win(current_tab)
    for i, winid in ipairs(wins) do
      local win_opt = opt.win
      if winid == top_win and opt.top_win ~= nil then
        win_opt = opt.top_win
      end
      table.insert(coms, tabline.render_win_label(winid, i == 1, i == #wins, win_opt))
    end
  end
  -- empty space in line
  table.insert(coms, { type = 'text', text = { '', hl = opt.hl } })
  -- tail
  if opt.tail then
    if opt.layout ~= 'active_wins_at_tail' then
      table.insert(coms, { type = 'text', text = { '%=' } })
    end
    for _, tail_item in ipairs(opt.tail) do
      table.insert(coms, { type = 'text', text = tail_item })
    end
  end

  return table.concat(vim.tbl_map(component.render, coms))
end

return tabline
