local M = {}

function M.open()
  return require("flompt.command").open()
end

function M.send()
  require("flompt.command").send()
end

function M.close()
  require("flompt.command").close()
end

return M
