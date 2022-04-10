local ShowError = require("flompt.vendor.misclib.error_handler").for_show_error()

local Prompt = require("flompt.core.prompt")

function ShowError.open()
  return Prompt.open()
end

function ShowError.send()
  local prompt, err = Prompt.get()
  if err then
    return err
  end
  return prompt:send()
end

function ShowError.close(bufnr)
  local prompt = Prompt.get(bufnr)
  if prompt == nil then
    return
  end
  return prompt:close()
end

function ShowError.sync(bufnr)
  vim.validate({ bufnr = { bufnr, "number" } })
  local prompt, err = Prompt.get(bufnr)
  if err then
    return err
  end
  return prompt:sync()
end

return ShowError:methods()
