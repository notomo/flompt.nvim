local window = require("flompt.window")
local Buffer = require("flompt.buffer").Buffer
local vim = vim

local M = {}

local Prompt = {}
Prompt.__index = Prompt
M.Prompt = Prompt

function Prompt.new(buffer)
  local tbl = {_buffer = buffer}
  return setmetatable(tbl, Prompt)
end

function Prompt.get_or_create()
  local buffer, err = Buffer.get_or_create()
  if err ~= nil then
    return nil, err
  end
  return Prompt.new(buffer), nil
end

function Prompt.get(bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  local buffer = Buffer.find(bufnr or vim.api.nvim_get_current_buf())
  if buffer == nil then
    return
  end
  return Prompt.new(buffer)
end

function Prompt.open(self)
  vim.api.nvim_win_set_cursor(0, {vim.fn.line("$"), 0})
  window.open(self._buffer.bufnr)
  self:sync()
end

function Prompt.send(self)
  window.open(self._buffer.bufnr)
  local cursor_line = window.cursor_line()
  self._buffer:send_line(cursor_line)
  if cursor_line == self._buffer:length() then
    self._buffer:append()
    window.set_cursor(cursor_line + 1)
  end
end

function Prompt.sync(self)
  local cursor_line = window.cursor_line()
  self._buffer:sync_line(cursor_line)
end

function Prompt.close()
  window.close()
end

return M
