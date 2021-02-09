local vim = vim

local M = {}

local Buffer = {}
Buffer.__index = Buffer
M.Buffer = Buffer

local FILETYPE = "flompt"

function Buffer.new(bufnr, source_bufnr, source_cmd)
  vim.validate({
    bufnr = {bufnr, "number"},
    source_bufnr = {source_bufnr, "number"},
    source_cmd = {source_cmd, "string"},
  })

  local new_line = ""
  if source_cmd == "cmd.exe" then
    new_line = "\r"
  end

  local tbl = {bufnr = bufnr, source_bufnr = source_bufnr, _new_line = new_line}
  return setmetatable(tbl, Buffer)
end

function Buffer.find(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  if vim.bo[bufnr].filetype == FILETYPE then
    local path = vim.api.nvim_buf_get_name(bufnr)
    local source_cmd = vim.fn.fnamemodify(path, ":t")
    local source_bufnr = vim.fn.matchstr(vim.fn.expand(path, ":p"), "\\vflompt://\\zs(\\d+)\\ze")
    return Buffer.new(bufnr, tonumber(source_bufnr), source_cmd)
  end

  return nil
end

function Buffer.get_or_create()
  local buffer = Buffer.find(vim.fn.bufnr("%"))
  if buffer ~= nil then
    return buffer, nil
  end

  if vim.bo.buftype ~= "terminal" then
    return nil, "Not supported &buftype: " .. vim.bo.buftype
  end

  local source_cmd = vim.fn.expand("%:t")
  local source_bufnr = vim.fn.bufnr("%")
  local name = ("flompt://%d/%s"):format(source_bufnr, source_cmd)
  local pattern = ("^%s$"):format(name)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, name)
    vim.bo[bufnr].filetype = FILETYPE
    vim.bo[bufnr].bufhidden = "wipe"
  end

  return Buffer.new(bufnr, source_bufnr, source_cmd), nil
end

function Buffer.send_line(self, cursor_line)
  vim.validate({cursor_line = {cursor_line, "number"}})
  local line = {
    vim.api.nvim_eval("\"\\<C-u>\"") .. vim.fn.getbufline(self.bufnr, cursor_line)[1],
    self._new_line,
  }
  self:_send(line)
end

function Buffer.sync_line(self, cursor_line)
  vim.validate({cursor_line = {cursor_line, "number"}})
  local line = vim.api.nvim_eval("\"\\<C-u>\"") .. vim.fn.getbufline(self.bufnr, cursor_line)[1]
  self:_send(line)
end

function Buffer._send(self, line)
  local id = vim.bo[self.source_bufnr].channel
  if id == "" then
    return
  end

  local running = vim.fn.jobwait({id}, 0)[1] == -1
  if not running then
    return
  end

  vim.fn.chansend(id, line)
end

function Buffer.append(self)
  vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, true, {""})
end

function Buffer.length(self)
  return vim.api.nvim_buf_line_count(self.bufnr)
end

function Buffer.exists(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})
  local path = vim.api.nvim_buf_get_name(bufnr)
  return vim.startswith(path, "flompt://")
end

return M
