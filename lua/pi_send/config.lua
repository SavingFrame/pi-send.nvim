local M = {}

local defaults = {
  tmux = {
    current_session_only = true,
  },
  send = {
    append_newline = true,
  },
  templates = {
    file = '@{file}',
    line = '@{file}:L{line}',
    position = '@{file}:L{line}:C{column}',
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
