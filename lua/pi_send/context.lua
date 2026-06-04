local selection = require('pi_send.selection')

local M = {}

function M.is_file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.bo[buf].buflisted
    and vim.tbl_contains({ '', 'help' }, vim.bo[buf].buftype)
    and name ~= ''
    and vim.fn.filereadable(name) == 1
end

function M.current()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    win = win,
    buf = buf,
    cwd = vim.fs.normalize(vim.fn.getcwd(win)),
    row = cursor[1],
    col = cursor[2] + 1,
    range = selection.range(buf),
  }
end

return M
