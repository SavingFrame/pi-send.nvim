local context = require('pi_send.context')
local location = require('pi_send.location')
local selection = require('pi_send.selection')

local M = {}

function M.render(opts)
  opts = type(opts) == 'string' and { msg = opts } or opts or {}
  local ctx = context.current()
  local msg = opts.msg or ''

  if opts.this ~= false then
    if context.is_file(ctx.buf) then
      msg = msg:gsub('{this}', '{position}')
    elseif msg:find('{this}', 1, true) then
      msg = msg:gsub('{this}', 'this') .. '\n\n{selection}'
    end
  end

  local replacements = {
    file = function()
      return context.is_file(ctx.buf) and location.format(ctx, 'file') or nil
    end,
    line = function()
      return context.is_file(ctx.buf) and location.format(ctx, 'line') or nil
    end,
    position = function()
      return context.is_file(ctx.buf) and location.format(ctx, 'position') or nil
    end,
    selection = function()
      return selection.text(ctx)
    end,
  }

  local ok = true
  msg = msg:gsub('{([%w_]+)}', function(key)
    local fn = replacements[key]
    local value = fn and fn()
    if not value then
      ok = false
      return ''
    end
    return value
  end)

  if not ok or msg == '' then
    return nil
  end
  return msg
end

return M
