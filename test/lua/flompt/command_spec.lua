local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("flompt", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open and send", function()
    local channel_id = helper.open_terminal_sync()
    helper.buffer_log()

    command("Flompt")
    assert.window_count(2)

    helper.input({"echo 123"})

    local before_line = vim.fn.line(".")
    command("Flompt send")
    helper.wait_terminal(channel_id)
    assert.line_number(before_line + 1)

    command("Flompt close")
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)

  it("can close", function()
    helper.open_terminal_sync()
    command("Flompt")

    command("Flompt close")
    assert.window_count(1)
  end)

  it("can close even if no prompt", function()
    helper.open_terminal_sync()
    command("Flompt close")
    assert.window_count(1)
  end)

  it("does not open two prompt from the same window", function()
    helper.open_terminal_sync()
    command("Flompt")

    command("wincmd p")
    command("Flompt")

    assert.window_count(2)
  end)

  it("cannot send to already exited terminal", function()
    local channel_id = helper.open_terminal_sync()

    command("Flompt")

    helper.input({"exit"})
    command("Flompt send")
    helper.wait_terminal(channel_id)

    helper.input({"echo 123"})
    command("Flompt send")
    helper.wait_terminal(channel_id)
  end)

  it("can exit with no error", function()
    command("tabedit")

    local channel_id = helper.open_terminal_sync()

    command("Flompt")

    helper.input({"exit"})
    command("Flompt send")
    helper.wait_terminal(channel_id)

    command("wincmd p")
    command("quit")
  end)

  it("can sync", function()
    local channel_id = helper.open_terminal_sync()

    command("Flompt start_sync")

    helper.input({"echo 123"})
    helper.emit_text_changed()
    helper.wait_terminal(channel_id)

    helper.buffer_log()
    command("wincmd p")
    assert.prompt("echo 123")

    command("Flompt send")
    helper.wait_terminal(channel_id)

    command("Flompt close")
    helper.buffer_log()

    assert.prompt("")
    assert.command_result_line("123")
  end)
end)
