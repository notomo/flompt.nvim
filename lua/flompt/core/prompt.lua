local Buffer = require("flompt.core.buffer")
local windowlib = require("flompt.vendor.misclib.window")
local cursorlib = require("flompt.vendor.misclib.cursor")
local vim = vim

local Prompt = {}
Prompt.__index = Prompt

function Prompt.new(buffer, window_id)
  vim.validate({
    buffer = { buffer, "table" },
    window_id = { window_id, "number" },
  })
  local tbl = { _buffer = buffer, _window_id = window_id }
  return setmetatable(tbl, Prompt)
end

function Prompt.open()
  local prompt = Prompt.get()
  if prompt ~= nil then
    prompt:enter()
    return require("flompt.vendor.promise").resolve()
  end

  local current_window_id = vim.api.nvim_get_current_win()
  local promise = Buffer.create()
  cursorlib.to_bottom(current_window_id)
  return promise:next(function(buffer)
    local column = math.floor(vim.o.columns / 2)
    local window_id = vim.api.nvim_win_call(current_window_id, function()
      return vim.api.nvim_open_win(buffer.bufnr, true, {
        relative = "editor",
        width = column - 4,
        height = math.floor(vim.o.lines * 0.4),
        row = 2,
        col = column,
        anchor = "NW",
        focusable = true,
        external = false,
        border = { { " ", "NormalFloat" } },
      })
    end)
    vim.api.nvim_set_current_win(window_id)
    vim.wo[window_id].number = false
    vim.wo[window_id].signcolumn = "no"
    cursorlib.to_bottom(window_id)

    Prompt.new(buffer, window_id):sync()
  end)
end

--- @return table: prompt
--- @return string|nil: error
function Prompt.get(bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  local buffer = Buffer.find(bufnr)
  if not buffer then
    return nil, "state is not found"
  end

  local window_id = vim.fn.win_findbuf(buffer.bufnr)[1]
  return Prompt.new(buffer, window_id)
end

function Prompt.send(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  self._buffer:send_line(row)
  if row == self._buffer:length() then
    self._buffer:append()
    cursorlib.to_bottom(self._window_id)
  end
end

function Prompt.sync(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  self._buffer:sync_line(row)
end

function Prompt.close(self)
  windowlib.safe_close(self._window_id)
end

function Prompt.enter(self)
  windowlib.safe_enter(self._window_id)
end

return Prompt
