local Prompt = require("flompt.prompt").Prompt
local messagelib = require("flompt.lib.message")

local M = {}

local Command = {}
Command.__index = Command
M.Command = Command

function Command.new(name, ...)
  local args = {...}
  local f = function()
    return Command[name](unpack(args))
  end

  local ok, msg = xpcall(f, debug.traceback)
  if not ok then
    return messagelib.error(msg)
  elseif msg then
    return messagelib.warn(msg)
  end
end

function Command.open()
  return Prompt.open()
end

function Command.send()
  local prompt = Prompt.get()
  if prompt == nil then
    return "state is not found"
  end
  return prompt:send()
end

function Command.close(bufnr)
  local prompt = Prompt.get(bufnr)
  if prompt == nil then
    return
  end
  return prompt:close()
end

function Command.sync(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})
  local prompt = Prompt.get(bufnr)
  if prompt == nil then
    return "state is not found"
  end
  return prompt:sync()
end

return M
