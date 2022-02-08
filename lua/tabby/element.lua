local element = {}

---@class TabbyHighlight
---@field fg    string hex color for foreground
---@field bg    string hex color for background
---@field style string Highlight gui style
---@field name  string highlight group name

local highlight_defaults = {
  fg = '',
  bg = '',
  style = '',
  name = '',
}

--- render highlight to statusline text
---@param hl string|TabbyHighlight highlight name or highlight object
---@return string statusline format text
function element.render_highlight(hl)
  if type(hl) == 'string' then
    return string.format('%%#%s#', hl)
  end
  hl = vim.tbl_extend('force', highlight_defaults, hl)
  if hl.fg == '' and hl.bg == '' and hl.style == '' then
    return ''
  end
  if hl.name == '' then
    hl.name = string.gsub(string.format('TabbyHl_%s_%s_%s', hl.fg, hl.bg, hl.style), '#', '')
  end
  local cmd = { 'hi', hl.name }
  if hl.fg ~= '' then
    table.insert(cmd, 'guifg=' .. hl.fg)
  end
  if hl.bg ~= '' then
    table.insert(cmd, 'guibg=' .. hl.bg)
  end
  if hl.style ~= '' then
    table.insert(cmd, 'gui=' .. hl.style)
  end
  local hl_str = table.concat(cmd, ' ')
  vim.cmd(hl_str)
  return string.format('%%#%s#', hl.name)
end

local layout_defaults = {
  max_width = 0,
  min_width = 0,
  justify = 'left',
}

--- render text layout to statusline text
---@param lo TabbyLayout
---@return string statusline text's prefix, string statusline text's suffix
function element.render_layout(lo)
  lo = vim.tbl_extend('force', layout_defaults, lo)
  if lo.max_width == 0 and lo.min_width == 0 then
    return '', ''
  end

  -- text is: %-{minwid}.{maxwid}(<string>%)
  local head = '%'
  local width = ''
  if lo.justify == 'left' then
    head = '%-'
  end
  if lo.max_width > 0 then
    width = string.format('%d.%d', lo.min_width, lo.max_width)
  elseif lo.min_width > 0 then
    width = lo.min_width
  end

  return head .. width .. '(', '%)'
end

---@class TabbyText
---@field [1] string|fun():string text content
---@field hl nil|string|TabbyHighlight
---@field lo nil|TabbyLayout

local text_defaults = {
  '',
  hl = '',
  lo = {},
}

--- render text object to statusline text
---@param text string|TabbyText
---@return string statusline string
function element.render_text(text)
  if type(text) == 'string' then
    return text
  end
  text = vim.tbl_extend('force', text_defaults, text)
  local content = text[1] or ''
  if type(content) == 'function' then
    content = content()
  end
  if content == '' then
    return ''
  end
  local hl = element.render_highlight(text.hl)
  local pre, suf = element.render_layout(text.lo)
  return table.concat({ pre, hl, content, suf })
end

---@return string statusline string
function element.render_spring()
  return '%='
end

return element
