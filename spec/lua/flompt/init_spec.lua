local helper = require("flompt.test.helper")
local flompt = helper.require("flompt")

describe("flompt", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open and send", function()
    helper.open_terminal_sync()
    helper.buffer_log()

    helper.wait(flompt.open())
    assert.window_count(2)

    helper.input({ "echo 123" })

    local before_line = vim.fn.line(".")
    flompt.send()
    helper.wait_terminal([[\v^123$]])
    assert.line_number(before_line + 1)

    flompt.close()
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)

  it("can close", function()
    helper.open_terminal_sync()
    helper.wait(flompt.open())

    flompt.close()
    assert.window_count(1)
  end)

  it("can close even if no prompt", function()
    helper.open_terminal_sync()
    flompt.close()
    assert.window_count(1)
  end)

  it("does not open two prompt from the same window", function()
    helper.open_terminal_sync()
    helper.wait(flompt.open())

    vim.cmd.wincmd("p")
    helper.wait(flompt.open())

    assert.window_count(2)
  end)

  it("cannot send to already exited terminal", function()
    helper.open_terminal_sync()

    helper.wait(flompt.open())

    helper.input({ "exit" })
    flompt.send()
    helper.wait_terminal("exit")

    helper.input({ "echo 123" })
    flompt.send()

    assert.exists_message("state is not found")
  end)

  it("can exit with no error", function()
    vim.cmd.tabedit()

    helper.open_terminal_sync()

    helper.wait(flompt.open())

    helper.input({ "exit" })
    flompt.send()
    helper.wait_terminal("^exit$")

    vim.cmd.wincmd("p")
    vim.cmd.quit()
  end)

  it("can sync", function()
    helper.open_terminal_sync()

    helper.wait(flompt.open())

    helper.input({ "echo 123" })
    helper.emit_text_changed()
    helper.wait_terminal("echo 123")

    helper.buffer_log()
    vim.cmd.wincmd("p")
    assert.prompt("echo 123")
    vim.cmd.wincmd("p")

    flompt.send()
    helper.wait_terminal("^123$")

    flompt.close()
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)

  it("can load bash history", function()
    helper.test_data:create_file(
      "test_history",
      [[
ls
cat]]
    )
    vim.env.HISTFILE = helper.test_data.full_path .. "test_history"
    helper.open_terminal_sync()

    helper.wait(flompt.open())

    assert.exists_pattern([[
ls
cat
]])
  end)

  it("raises error if history file is not found", function()
    local history_file = helper.test_data.full_path .. "invalid"
    vim.env.HISTFILE = history_file
    helper.open_terminal_sync()

    helper.wait(flompt.open())

    assert.exists_message("cannot open: " .. history_file)
  end)
end)
