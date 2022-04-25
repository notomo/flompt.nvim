local M = {}

function M.load(bufnr)
  local promise
  local exe = vim.o.shell
  if M._has("zsh", exe) then
    promise = M._zsh(exe)
  elseif M._has("bash", exe) then
    promise = M._bash(exe)
  end
  return promise:next(function(lines)
    if lines == nil then
      return
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end)
end

function M._has(name, exe)
  return exe == name or vim.endswith(exe, "/" .. name)
end

local new_sender = function(resolve, reject)
  local sender
  sender = vim.loop.new_async(function(v)
    local decoded = vim.mpack.decode(v)
    if decoded.error then
      reject(decoded.error)
    else
      vim.schedule(function()
        resolve(decoded.lines)
      end)
    end
    sender:close()
  end)
  return sender
end

function M._zsh(exe)
  local file_path = vim.fn.systemlist({ exe, "-i", "-c", "echo ${HISTFILE}" })[1]
  if file_path == nil then
    return require("flompt.vendor.promise").resolve()
  end

  return require("flompt.vendor.promise").new(function(resolve, reject)
    local sender = new_sender(resolve, reject)
    vim.loop.new_thread(function(async, path)
      local f = io.open(path, "r")
      if f == nil then
        return async:send(vim.mpack.encode({ error = "cannot open: " .. path }))
      end

      local lines = vim.split(f:read("*a"), "\n", true)
      lines = vim.tbl_map(function(line)
        return line:gsub(".*;", "")
      end, lines)
      return async:send(vim.mpack.encode({ lines = lines }))
    end, sender, file_path)
  end)
end

function M._bash(exe)
  local file_path = vim.fn.systemlist({ exe, "-c", "echo ${HISTFILE}" })[1]
  if file_path == nil then
    return require("flompt.vendor.promise").resolve()
  end

  return require("flompt.vendor.promise").new(function(resolve, reject)
    local sender = new_sender(resolve, reject)
    vim.loop.new_thread(function(async, path)
      local f = io.open(path, "r")
      if f == nil then
        return async:send(vim.mpack.encode({ error = "cannot open: " .. path }))
      end

      local lines = vim.split(f:read("*a"), "\n", true)
      return async:send(vim.mpack.encode({ lines = lines }))
    end, sender, file_path)
  end)
end

return M
