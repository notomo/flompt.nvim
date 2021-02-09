local buffers = require"flompt/buffer".buffers
local vim = vim

local M = {}

local get = function()
  local ids = vim.api.nvim_tabpage_list_wins(0)
  for _, id in ipairs(ids) do
    local bufnr = vim.fn.winbufnr(id)
    if buffers.exists(bufnr) then
      return id
    end
  end
end

M.open = function(bufnr)
  local id = get()
  if id ~= nil and vim.api.nvim_win_is_valid(id) then
    vim.api.nvim_set_current_win(id)
    return
  end
  local column = math.floor(vim.o.columns / 2)
  vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = column - 3,
    height = 20,
    row = 3,
    col = column,
    anchor = "NW",
    focusable = true,
    external = false,
  })
end

M.set_cursor = function(line_number)
  local id = get()
  if id == "" or not vim.api.nvim_win_is_valid(id) then
    return
  end
  vim.api.nvim_win_set_cursor(id, {line_number, 0})
end

M.cursor_line = function()
  local id = get()
  local pos = vim.api.nvim_win_get_cursor(id)
  return pos[1]
end

local close_window = function(id)
  if id == "" then
    return
  end
  if not vim.api.nvim_win_is_valid(id) then
    return
  end
  vim.api.nvim_win_close(id, true)
end

M.close = function()
  local id = get()
  if id == nil then
    return
  end
  close_window(id)
end

return M
