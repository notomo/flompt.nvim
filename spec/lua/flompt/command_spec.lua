local helper = require("flompt.lib.testlib.helper")
local flompt = helper.require("flompt")

describe("flompt", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open and send", function()
    local channel_id = helper.open_terminal_sync()
    helper.buffer_log()

    flompt.open()
    assert.window_count(2)

    helper.input({"echo 123"})

    local before_line = vim.fn.line(".")
    flompt.send()
    helper.wait_terminal(channel_id)
    assert.line_number(before_line + 1)

    flompt.close()
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)

  it("can close", function()
    helper.open_terminal_sync()
    flompt.open()

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
    flompt.open()

    vim.cmd("wincmd p")
    flompt.open()

    assert.window_count(2)
  end)

  it("cannot send to already exited terminal", function()
    local channel_id = helper.open_terminal_sync()

    flompt.open()

    helper.input({"exit"})
    flompt.send()
    helper.wait_terminal(channel_id)

    helper.input({"echo 123"})
    flompt.send()
    helper.wait_terminal(channel_id)
  end)

  it("can exit with no error", function()
    vim.cmd("tabedit")

    local channel_id = helper.open_terminal_sync()

    flompt.open()

    helper.input({"exit"})
    flompt.send()
    helper.wait_terminal(channel_id)

    vim.cmd("wincmd p")
    vim.cmd("quit")
  end)

  it("can sync", function()
    local channel_id = helper.open_terminal_sync()

    flompt.open()

    helper.input({"echo 123"})
    helper.emit_text_changed()
    helper.wait_terminal(channel_id)

    helper.buffer_log()
    vim.cmd("wincmd p")
    assert.prompt("echo 123")
    vim.cmd("wincmd p")

    flompt.send()
    helper.wait_terminal(channel_id)

    flompt.close()
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)

  it("can load bash history", function()
    helper.new_file("test_history", [[
ls
cat]])
    vim.env.HISTFILE = helper.test_data_path .. "test_history"
    local channel_id = helper.open_terminal_sync()

    flompt.open()
    helper.wait_terminal(channel_id)

    assert.exists_pattern([[
ls
cat
]])
  end)
end)
