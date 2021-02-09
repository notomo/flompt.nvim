local Command = require("flompt.command").Command

local M = {}

function M.open()
  Command.new("open")
end

function M.send()
  Command.new("send")
end

function M.close()
  Command.new("close")
end

return M
