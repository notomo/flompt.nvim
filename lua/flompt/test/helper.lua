local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local helper = require("vusted.helper")
helper.cleanup()

helper.root = helper.find_plugin_root(plugin_name)

local prompt_name = "test_prompt"
local prompt = ("[%s]"):format(prompt_name)

vim.env.PS1 = prompt

function helper.before_each()
  vim.o.shell = "bash"
  vim.env.HISTFILE = ""
  helper.test_data = require("flompt.vendor.misclib.test.data_dir").setup(helper.root)
end

function helper.after_each()
  helper.test_data:teardown()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
  print(" ")
end

function helper.input(texts)
  vim.api.nvim_put(texts, "c", true, true)
end

function helper.buffer_log()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

function helper.wait_terminal(pattern)
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

function helper.open_terminal_sync()
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
  helper.wait_terminal(prompt)
end

function helper.on_finished()
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

function helper.wait(promise)
  local on_finished = helper.on_finished()
  promise:finally(function()
    on_finished()
  end)
  on_finished:wait()
end

function helper._search_last_prompt()
  vim.cmd.normal({ args = { "G" }, bang = true })
  local result = vim.fn.search(prompt_name, "bW")
  if result == 0 then
    local msg = ("not found prompt: %s"):format(prompt_name)
    assert(false, msg)
  end
  return result
end

function helper.emit_text_changed()
  vim.api.nvim_exec_autocmds("TextChanged", {
    group = "flompt:" .. vim.fn.bufnr("%"),
    modeline = false,
  })
end

local asserts = require("vusted.assert").asserts
local asserters = require(plugin_name .. ".vendor.assertlib").list()
require(plugin_name .. ".vendor.misclib.test.assert").register(asserts.create, asserters)

asserts.create("prompt"):register_eq(function()
  helper._search_last_prompt()
  return vim.fn.getline("."):sub(#prompt + 1)
end)

asserts.create("command_result_line"):register_eq(function()
  helper._search_last_prompt()
  vim.cmd.normal({ args = { "k" }, bang = true })
  return vim.fn.getline(".")
end)

return helper
