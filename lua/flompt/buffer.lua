local M = {}

local Buffer = function(bufnr, source_bufnr, source_cmd)
  local send = function(data)
    local id = vim.api.nvim_buf_get_option(source_bufnr, "channel")
    if id == "" then
      return
    end

    local running = vim.fn.jobwait({id}, 0)[1] == -1
    if not running then
      return
    end

    vim.fn.chansend(id, data)
  end

  local new_line = ""
  if source_cmd == "cmd.exe" then
    new_line = "\r"
  end

  return {
    bufnr = bufnr,
    source_bufnr = source_bufnr,
    append = function()
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
    end,
    len = function()
      return vim.api.nvim_buf_line_count(bufnr)
    end,
    send_line = function(cursor_line)
      local line = {
        vim.api.nvim_eval('"\\<C-u>"') .. vim.fn.getbufline(bufnr, cursor_line)[1],
        new_line
      }
      send(line)
    end,
    sync_line = function(cursor_line)
      local line = vim.api.nvim_eval('"\\<C-u>"') .. vim.fn.getbufline(bufnr, cursor_line)[1]
      send(line)
    end
  }
end

local buffers = {}
local filetype = "flompt"

buffers.find = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if vim.api.nvim_buf_get_option(bufnr, "filetype") == filetype then
    local source_cmd = vim.fn.fnamemodify(path, ":t")
    local source_bufnr = vim.fn.matchstr(vim.fn.expand(path, ":p"), "\\vflompt://\\zs(\\d+)\\ze")
    return Buffer(bufnr, source_bufnr, source_cmd)
  end
  return nil
end

buffers.get_or_create = function()
  local buffer = buffers.find(vim.fn.bufnr("%"))
  if buffer ~= nil then
    return buffer, nil
  end

  if vim.bo.buftype ~= "terminal" then
    return nil, "Not supported &buftype: " .. vim.bo.buftype
  end

  local source_cmd = vim.fn.expand("%:t")
  local source_bufnr = vim.fn.bufnr("%")
  local name = ("flompt://%d/%s"):format(source_bufnr, source_cmd)
  local pattern = ("^%s$"):format(name)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, name)
    vim.api.nvim_buf_set_option(bufnr, "filetype", filetype)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  end

  return Buffer(bufnr, source_bufnr, source_cmd), nil
end

buffers.exists = function(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return vim.startswith(path, "flompt://")
end

M.buffers = buffers

return M
