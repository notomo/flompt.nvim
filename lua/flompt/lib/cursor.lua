local M = {}

function M.to_bottom(bufnr, window_id)
  vim.validate({bufnr = {bufnr, "number", true}, window_id = {window_id, "number", true}})
  local count = vim.api.nvim_buf_line_count(bufnr or 0)
  vim.api.nvim_win_set_cursor(window_id or 0, {count, 0})
end

return M
