local Buffer = require("flompt.buffer").Buffer
local windowlib = require("flompt.lib.window")
local cursorlib = require("flompt.lib.cursor")
local vim = vim

local M = {}

local Prompt = {}
Prompt.__index = Prompt
M.Prompt = Prompt

function Prompt.new(buffer, window_id)
  vim.validate({buffer = {buffer, "table"}, window_id = {window_id, "number"}})
  local tbl = {_buffer = buffer, _window_id = window_id}
  return setmetatable(tbl, Prompt)
end

function Prompt.open()
  local prompt = Prompt.get()
  if prompt ~= nil then
    return prompt:enter()
  end

  local buffer, err = Buffer.create()
  if err ~= nil then
    return err
  end
  cursorlib.to_bottom()

  local column = math.floor(vim.o.columns / 2)
  local window_id = vim.api.nvim_open_win(buffer.bufnr, true, {
    relative = "editor",
    width = column - 2,
    height = math.floor(vim.o.lines * 0.4),
    row = 2,
    col = column,
    anchor = "NW",
    focusable = true,
    external = false,
  })

  Prompt.new(buffer, window_id):sync()
end

function Prompt.get(bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  local buffer = Buffer.find(bufnr)
  if buffer == nil then
    return
  end

  local window_id = vim.fn.win_findbuf(buffer.bufnr)[1]
  return Prompt.new(buffer, window_id)
end

function Prompt.send(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  self._buffer:send_line(row)
  if row == self._buffer:length() then
    self._buffer:append()
    cursorlib.to_bottom(self._buffer.bufnr, self._window_id)
  end
end

function Prompt.sync(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  self._buffer:sync_line(row)
end

function Prompt.close(self)
  windowlib.close(self._window_id)
end

function Prompt.enter(self)
  windowlib.enter(self._window_id)
end

return M
