local M = {}

function M.load(bufnr)
  local lines
  local exe = vim.o.shell
  if M._has("zsh", exe) then
    lines = M._zsh(exe)
  elseif M._has("bash", exe) then
    lines = M._bash(exe)
  end
  if lines == nil then
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M._has(name, exe)
  return exe == name or vim.endswith(exe, "/" .. name)
end

function M._zsh(exe)
  local path = vim.fn.systemlist({ exe, "-i", "-c", "echo ${HISTFILE}" })[1]
  if path == nil then
    return
  end

  local f = io.open(path, "r")
  if f == nil then
    return
  end

  local lines = vim.split(f:read("*a"), "\n", true)
  return vim.tbl_map(function(line)
    return line:gsub(".*;", "")
  end, lines)
end

function M._bash(exe)
  local path = vim.fn.systemlist({ exe, "-c", "echo ${HISTFILE}" })[1]
  if path == nil then
    return
  end

  local f = io.open(path, "r")
  if f == nil then
    return
  end

  return vim.split(f:read("*a"), "\n", true)
end

return M
