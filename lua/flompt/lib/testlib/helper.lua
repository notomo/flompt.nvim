local M = {}

local root, err = require("flompt/lib/path").find_root("flompt/*.lua")
if err ~= nil then
  error(err)
end
M.root = root

M.command = function(cmd)
  vim.api.nvim_command(cmd)
end

local prompt_name = "test_prompt"
local prompt = ("[%s]"):format(prompt_name)

vim.o.shell = "bash"

M.command(("let $PS1 = '%s'"):format(prompt))

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
  -- HACK: How to wait terminal drawing?
  M.command("sleep 300ms")
end

M.open_terminal_sync = function()
  local channel_id = vim.fn.termopen({"bash", "--noprofile", "--norc", "-eo", "pipefail"}, {
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

local vassert = require("vusted.assert")
local asserts = vassert.asserts

asserts.create("window_count"):register_eq(function()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end)

asserts.create("prompt"):register_eq(function()
  M._search_last_prompt()
  return vim.fn.getline("."):sub(#prompt + 1)
end)

asserts.create("command_result_line"):register_eq(function()
  M._search_last_prompt()
  M.command("normal! k")
  return vim.fn.getline(".")
end)

asserts.create("line_number"):register_eq(function()
  return vim.fn.line(".")
end)

return M
