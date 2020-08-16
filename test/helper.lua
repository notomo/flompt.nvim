local M = {}

M.root = vim.fn.getcwd()

M.command = function(cmd)
  vim.api.nvim_command(cmd)
end

local prompt_name = "test_prompt"
local prompt = ("[%s]"):format(prompt_name)

vim.o.shell = "bash"

M.command(("let $PS1 = '%s'"):format(prompt))

-- NOTICE: for termopen callback
vim.api.nvim_exec([[
function! FlomptTestOnStdout(id, data, event) abort
    echomsg '[stdout]' string(a:data)
endfunction

function! FlomptTestOnStderr(id, data, event) abort
    echomsg '[stderr]' string(a:data)
endfunction

function! FlomptTestOnExit(id, exit_code, event) abort
    echomsg '[exit] exit_code: ' a:exit_code
endfunction
]], false)

M.before_each = function()
  M.command("filetype on")
  M.command("syntax enable")
end

M.after_each = function()
  M.command("tabedit")
  M.command("tabonly!")
  M.command("silent! %bwipeout!")
  M.command("filetype off")
  M.command("syntax off")
  print(" ")
end

M.input = function(texts)
  vim.api.nvim_put(texts, "c", true, true)
end

M.buffer_log = function()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

M.wait_terminal = function(_)
  -- HACk: How to wait terminal drawing?
  M.command("sleep 300ms")
end

M.open_terminal_sync = function()
  local channel_id = vim.fn.termopen({"bash", "--noprofile", "--norc", "-eo", "pipefail"}, {
    on_stdout = "FlomptTestOnStdout",
    on_stderr = "FlomptTestOnStderr",
    on_exit = "FlomptTestOnExit",
  })
  M.wait_terminal(channel_id)
  return channel_id
end

M._search_last_prompt = function()
  M.command("normal! G")
  local result = vim.fn.search(prompt_name, "bW")
  if result == 0 then
    local msg = ("not found prompt: %s"):format(prompt_name)
    assert(false, msg)
  end
  return result
end

M.emit_text_changed = function()
  M.command(("doautocmd flompt:%s TextChanged"):format(vim.fn.bufnr("%")))
end

local assert = require("luassert")
local AM = {}

AM.window_count = function(expected)
  local actual = vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
  local msg = ("window count should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.terminal = function()
  local actual = vim.bo.buftype
  local expected = "terminal"
  assert.equals(expected, actual, "&buftype should be terminal")
end

AM.prompt = function(expected)
  AM.terminal()
  M._search_last_prompt()
  local actual = vim.fn.getline("."):sub(#prompt + 1)
  local msg = ("current prompt should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.command_result_line = function(expected)
  AM.terminal()
  M._search_last_prompt()
  M.command("normal! k")
  local actual = vim.fn.getline(".")
  local msg = ("command result line should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.line_number = function(expected)
  local actual = vim.fn.line(".")
  local msg = ("line number should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

M.assert = AM

return M
