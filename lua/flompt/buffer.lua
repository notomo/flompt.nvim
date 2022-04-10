local history = require("flompt.history")
local vim = vim

local M = {}

local Buffer = {}
Buffer.__index = Buffer
M.Buffer = Buffer

local FILETYPE = "flompt"
local PATH_PREFIX = FILETYPE .. "://"

function Buffer.new(bufnr, source_bufnr, source_cmd)
  vim.validate({
    bufnr = { bufnr, "number" },
    source_bufnr = { source_bufnr, "number" },
    source_cmd = { source_cmd, "string" },
  })

  local new_line = ""
  if source_cmd == "cmd.exe" then
    new_line = "\r"
  end

  local tbl = { bufnr = bufnr, _source_bufnr = source_bufnr, _new_line = new_line }
  return setmetatable(tbl, Buffer)
end

function Buffer._find()
  local ids = vim.api.nvim_tabpage_list_wins(0)
  for _, id in ipairs(ids) do
    local bufnr = vim.fn.winbufnr(id)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if vim.startswith(path, PATH_PREFIX) then
      return bufnr
    end
  end
end

function Buffer.find(bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  bufnr = bufnr or Buffer._find()

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  if vim.bo[bufnr].filetype == FILETYPE then
    local path = vim.api.nvim_buf_get_name(bufnr)
    local source_cmd = vim.fn.fnamemodify(path, ":t")
    local pattern = ("\\v%s\\zs(\\d+)\\ze"):format(PATH_PREFIX)
    local source_bufnr = vim.fn.matchstr(path, pattern)
    return Buffer.new(bufnr, tonumber(source_bufnr), source_cmd)
  end

  return nil
end

function Buffer.create()
  if vim.bo.buftype ~= "terminal" then
    return nil, "Not supported &buftype: " .. vim.bo.buftype
  end

  local source_cmd = vim.fn.expand("%:t")
  local source_bufnr = vim.fn.bufnr("%")
  local name = ("%s%d/%s"):format(PATH_PREFIX, source_bufnr, source_cmd)
  local pattern = ("^%s$"):format(name)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, name)
    vim.bo[bufnr].filetype = FILETYPE
    vim.bo[bufnr].bufhidden = "wipe"
    history.load(bufnr)
  end

  vim.cmd(("autocmd BufWipeout <buffer=%s> lua require('flompt.command').close(%s)"):format(source_bufnr, bufnr))
  vim.cmd(("autocmd TermClose <buffer=%s> lua require('flompt.command').close(%s)"):format(source_bufnr, bufnr))

  local group_name = "flompt:" .. bufnr
  vim.cmd(("augroup %s"):format(group_name))
  vim.cmd(
    ("autocmd %s TextChanged <buffer=%s> lua require('flompt.command').sync(%s)"):format(group_name, bufnr, bufnr)
  )
  vim.cmd(
    ("autocmd %s TextChangedI <buffer=%s> lua require('flompt.command').sync(%s)"):format(group_name, bufnr, bufnr)
  )
  vim.cmd(
    ("autocmd %s TextChangedP <buffer=%s> lua require('flompt.command').sync(%s)"):format(group_name, bufnr, bufnr)
  )
  vim.cmd("augroup END")

  return Buffer.new(bufnr, source_bufnr, source_cmd), nil
end

local CTRL_U = vim.api.nvim_eval('"\\<C-u>"')

function Buffer.send_line(self, row)
  vim.validate({ row = { row, "number" } })
  local line = {
    CTRL_U .. vim.api.nvim_buf_get_lines(self.bufnr, row - 1, row, false)[1],
    self._new_line,
  }
  self:_send(line)
end

function Buffer.sync_line(self, row)
  vim.validate({ row = { row, "number" } })
  local line = { CTRL_U .. vim.api.nvim_buf_get_lines(self.bufnr, row - 1, row, false)[1] }
  self:_send(line)
end

function Buffer._send(self, line)
  local id = vim.bo[self._source_bufnr].channel
  if id == "" then
    return
  end

  local running = vim.fn.jobwait({ id }, 0)[1] == -1
  if not running then
    return
  end

  vim.fn.chansend(id, line)
end

function Buffer.append(self)
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, true, { "" })
end

function Buffer.length(self)
  return vim.api.nvim_buf_line_count(self.bufnr)
end

return M
