local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local M = require("vusted.helper")

M.root = M.find_plugin_root(plugin_name)

local prompt_name = "test_prompt"
local prompt = ("[%s]"):format(prompt_name)

vim.o.shell = "bash"
vim.env.PS1 = prompt

function M.before_each()
  vim.env.HISTFILE = ""
  M.test_data_path = "spec/test_data/" .. math.random(1, 2 ^ 30) .. "/"
  M.test_data_dir = M.root .. "/" .. M.test_data_path
  M.new_directory("")
  vim.cmd("filetype on")
  vim.cmd("syntax enable")
end

function M.after_each()
  vim.cmd("tabedit")
  vim.cmd("tabonly!")
  vim.cmd("silent! %bwipeout!")
  vim.cmd("filetype off")
  vim.cmd("syntax off")
  vim.cmd("messages clear")
  vim.fn.delete(M.root .. "/spec/test_data", "rf")
  M.cleanup_loaded_modules(plugin_name)
  print(" ")
end

function M.input(texts)
  vim.api.nvim_put(texts, "c", true, true)
end

function M.buffer_log()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

function M.new_file(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({ ... }) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.new_directory(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

function M.delete(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

function M.wait_terminal(pattern)
  local bufnrs = vim.tbl_filter(function(bufnr)
    return vim.bo[bufnr].buftype == "terminal"
  end, vim.fn.tabpagebuflist())
  local bufnr = bufnrs[1]
  local ok = vim.wait(1000, function()
    local result
    vim.api.nvim_buf_call(bufnr, function()
      result = vim.fn.search(pattern)
    end)
    return result ~= 0
  end)
  if not ok then
    error("timeout: not found pattern: " .. pattern)
  end
end

function M.open_terminal_sync()
  vim.fn.termopen({ "bash", "--noprofile", "--norc", "-eo", "pipefail" }, {
    on_stdout = function(_, data, _)
      local msg = "[stdout] " .. table.concat(data, "\n")
      vim.api.nvim_out_write(msg .. "\n")
    end,
    on_stderr = function(_, data, _)
      local msg = "[stderr] " .. table.concat(data, "\n")
      vim.api.nvim_out_write(msg .. "\n")
    end,
    on_exit = function(_, exit_code, _)
      local msg = "[exit] " .. exit_code
      vim.api.nvim_out_write(msg .. "\n")
    end,
  })
  M.wait_terminal(prompt)
end

function M.on_finished()
  local finished = false
  return setmetatable({
    wait = function()
      local ok = vim.wait(1000, function()
        return finished
      end, 10, false)
      if not ok then
        error("wait timeout")
      end
    end,
  }, {
    __call = function()
      finished = true
    end,
  })
end

function M.wait(promise)
  local on_finished = M.on_finished()
  promise:finally(function()
    on_finished()
  end)
  on_finished:wait()
end

function M._search_last_prompt()
  vim.cmd("normal! G")
  local result = vim.fn.search(prompt_name, "bW")
  if result == 0 then
    local msg = ("not found prompt: %s"):format(prompt_name)
    assert(false, msg)
  end
  return result
end

function M.emit_text_changed()
  vim.cmd(("doautocmd flompt:%s TextChanged"):format(vim.fn.bufnr("%")))
end

local asserts = require("vusted.assert").asserts

asserts.create("window_count"):register_eq(function()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end)

asserts.create("prompt"):register_eq(function()
  M._search_last_prompt()
  return vim.fn.getline("."):sub(#prompt + 1)
end)

asserts.create("command_result_line"):register_eq(function()
  M._search_last_prompt()
  vim.cmd("normal! k")
  return vim.fn.getline(".")
end)

asserts.create("line_number"):register_eq(function()
  return vim.fn.line(".")
end)

asserts.create("exists_pattern"):register(function(self)
  return function(_, args)
    local pattern = args[1]
    pattern = pattern:gsub("\n", "\\n")
    local result = vim.fn.search(pattern, "n")
    self:set_positive(("`%s` not found"):format(pattern))
    self:set_negative(("`%s` found"):format(pattern))
    return result ~= 0
  end
end)

asserts.create("exists_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    self:set_positive(("`%s` not found message"):format(expected))
    self:set_negative(("`%s` found message"):format(expected))
    local messages = vim.split(vim.api.nvim_exec("messages", true), "\n")
    for _, msg in ipairs(messages) do
      if msg:match(expected) then
        return true
      end
    end
    return false
  end
end)

return M
