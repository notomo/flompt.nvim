local window = require "flompt/window"
local buffers = require "flompt/buffer".buffers

local M = {}

local sync = function(buffer)
  local cursor_line = window.cursor_line()
  buffer.sync_line(cursor_line)
end

local close = function()
  window.close()
end

M.get_or_create = function()
  local buffer, err = buffers.get_or_create()
  if err ~= nil then
    return nil, err
  end
  local bufnr = buffer.bufnr
  local source_bufnr = buffer.source_bufnr

  local open = function()
    vim.api.nvim_win_set_cursor(0, {vim.fn.line("$"), 0})
    window.open(bufnr)
  end

  vim.api.nvim_command(
    ("autocmd BufWipeout <buffer=%s> lua require('flompt/prompt').on_source_buffer_wiped(%s)"):format(
      source_bufnr,
      bufnr
    )
  )
  vim.api.nvim_command(
    ("autocmd TermClose <buffer=%s> lua require('flompt/prompt').on_term_closed(%s)"):format(source_bufnr, bufnr)
  )

  local group_name = "flompt:" .. bufnr

  return {
    open = open,
    close = close,
    send = function()
      window.open(bufnr)
      local cursor_line = window.cursor_line()
      buffer.send_line(cursor_line)
      if cursor_line == buffer.len() then
        buffer.append()
        window.set_cursor(cursor_line + 1)
      end
    end,
    start_sync = function()
      open()
      vim.api.nvim_command(("augroup %s"):format(group_name))
      vim.api.nvim_command(
        ("autocmd %s TextChanged <buffer=%s> lua require('flompt/prompt').on_text_changed(%s)"):format(
          group_name,
          bufnr,
          bufnr
        )
      )
      vim.api.nvim_command(
        ("autocmd %s TextChangedI <buffer=%s> lua require('flompt/prompt').on_text_changed(%s)"):format(
          group_name,
          bufnr,
          bufnr
        )
      )
      vim.api.nvim_command(
        ("autocmd %s TextChangedP <buffer=%s> lua require('flompt/prompt').on_text_changed(%s)"):format(
          group_name,
          bufnr,
          bufnr
        )
      )
      vim.api.nvim_command("augroup END")
      sync(buffer)
    end,
    stop_sync = function()
      vim.api.nvim_command(("autocmd! %s TextChanged"):format(group_name))
    end
  }, nil
end

M.on_text_changed = function(bufnr)
  local buffer = buffers.find(bufnr)
  if buffer == nil then
    return
  end
  sync(buffer)
end

M.on_term_closed = function(bufnr)
  local buffer = buffers.find(bufnr)
  if buffer == nil then
    return
  end
  close()
end

M.on_source_buffer_wiped = function(bufnr)
  local buffer = buffers.find(bufnr)
  if buffer == nil then
    return
  end
  close()
end

return M
