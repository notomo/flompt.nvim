local M = {}

function M.load(bufnr)
  local lines
  local shell = vim.o.shell
  if shell == "zsh" then
    lines = M._zsh()
  elseif shell == "bash" then
    lines = M._bash()
  end
  if lines == nil then
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M._zsh()
  local path = vim.fn.systemlist({vim.o.shell, "-i", "-c", "echo $HISTFILE"})[1]
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

function M._bash()
  local path = vim.fn.systemlist({"bash", "-c", "echo ${HISTFILE}"})[1]
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
