local M = {}

local defaults = {
  tmux = {
    current_session_only = true,
  },
  send = {
    append_newline = true,
  },
  templates = {
    file = '{location_file}',
    line = '{location_line}',
    position = '{location_position}',
    selection = '{selection}',
  },
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts)
  return M.options
end

function M.get()
  return M.options
end

return M
