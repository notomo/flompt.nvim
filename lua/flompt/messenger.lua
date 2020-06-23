local M = {}

local default = function(msg)
  vim.api.nvim_err_write(msg .. "\n")
end

M.clear = function()
  M.echo = default
end

M.echo = function(msg)
  default(msg)
end

M.warn = function(msg)
  M.echo("[flompt] " .. msg)
end

return M
