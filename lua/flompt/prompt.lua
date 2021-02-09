local window = require("flompt.window")
local Buffer = require("flompt.buffer").Buffer
local vim = vim

local M = {}

local Prompt = {}
Prompt.__index = Prompt
M.Prompt = Prompt

function Prompt.get_or_create()
  local buffer, err = Buffer.get_or_create()
  if err ~= nil then
    return nil, err
  end
  local bufnr = buffer.bufnr
  local source_bufnr = buffer.source_bufnr

  vim.cmd(("autocmd BufWipeout <buffer=%s> lua require('flompt.prompt').on_source_buffer_wiped(%s)"):format(source_bufnr, bufnr))
  vim.cmd(("autocmd TermClose <buffer=%s> lua require('flompt.prompt').on_term_closed(%s)"):format(source_bufnr, bufnr))

  local tbl = {_buffer = buffer, _bufnr = bufnr, _group_name = "flompt:" .. bufnr}
  return setmetatable(tbl, Prompt)
end

function Prompt.open(self)
  vim.api.nvim_win_set_cursor(0, {vim.fn.line("$"), 0})
  window.open(self._bufnr)

  vim.cmd(("augroup %s"):format(self._group_name))
  vim.cmd(("autocmd %s TextChanged <buffer=%s> lua require('flompt.prompt').on_text_changed(%s)"):format(self._group_name, self._bufnr, self._bufnr))
  vim.cmd(("autocmd %s TextChangedI <buffer=%s> lua require('flompt.prompt').on_text_changed(%s)"):format(self._group_name, self._bufnr, self._bufnr))
  vim.cmd(("autocmd %s TextChangedP <buffer=%s> lua require('flompt.prompt').on_text_changed(%s)"):format(self._group_name, self._bufnr, self._bufnr))
  vim.cmd("augroup END")

  Prompt.sync(self._buffer)
end

function Prompt.send(self)
  window.open(self._bufnr)
  local cursor_line = window.cursor_line()
  self._buffer:send_line(cursor_line)
  if cursor_line == self._buffer:length() then
    self._buffer:append()
    window.set_cursor(cursor_line + 1)
  end
end

function Prompt.sync(buffer)
  local cursor_line = window.cursor_line()
  buffer:sync_line(cursor_line)
end

function Prompt.close()
  window.close()
end

M.on_text_changed = function(bufnr)
  local buffer = Buffer.find(bufnr)
  if buffer == nil then
    return
  end
  Prompt.sync(buffer)
end

M.on_term_closed = function(bufnr)
  local buffer = Buffer.find(bufnr)
  if buffer == nil then
    return
  end
  Prompt.close()
end

M.on_source_buffer_wiped = function(bufnr)
  local buffer = Buffer.find(bufnr)
  if buffer == nil then
    return
  end
  Prompt.close()
end

return M
