local prompts = require "flompt/prompt"
local messenger = require "flompt/messenger"

local M = {}

local cmds = {
  open = function(prompt)
    return prompt.open()
  end,
  close = function(prompt)
    return prompt.close()
  end,
  send = function(prompt)
    return prompt.send()
  end,
  start_sync = function(prompt)
    return prompt.start_sync()
  end,
  stop_sync = function(prompt)
    return prompt.stop_sync()
  end,
}

M.main = function(...)
  local args = {...}

  local name = args[1]
  if name == nil then
    name = "open"
  end
  local cmd = cmds[name]

  local prompt, err = prompts.get_or_create()
  if err ~= nil then
    return messenger.warn(err)
  end

  cmd(prompt)
end

return M
