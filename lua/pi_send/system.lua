local M = {}

function M.run(cmd, opts)
  opts = opts or {}
  local obj = vim.system(cmd, opts):wait()
  if obj.code ~= 0 then
    local err = vim.trim(obj.stderr or '')
    error(err ~= '' and err or ('command failed: ' .. table.concat(cmd, ' ')))
  end
  return obj.stdout or ''
end

return M
