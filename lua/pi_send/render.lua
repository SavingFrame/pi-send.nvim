local config = require('pi_send.config')
local context = require('pi_send.context')
local location = require('pi_send.location')
local selection = require('pi_send.selection')

local M = {}

local function file_path(ctx)
  local name = vim.api.nvim_buf_get_name(ctx.buf)
  local ok, rel = pcall(vim.fs.relpath, ctx.cwd, name)
  if ok and rel and rel ~= '' and rel ~= '.' then
    return rel
  end
  return name
end

local function range(ctx)
  local from = ctx.range and ctx.range.from or { ctx.row, ctx.col - 1 }
  local to = ctx.range and ctx.range.to or from
  return from, to
end

local function vars(ctx)
  local from, to = range(ctx)
  local is_file = context.is_file(ctx.buf)
  return {
    ctx = ctx,
    file = is_file and file_path(ctx) or nil,
    line = from[1],
    column = from[2] + 1,
    start_line = from[1],
    start_column = from[2] + 1,
    end_line = to[1],
    end_column = to[2] + 1,
    location_file = is_file and location.format(ctx, 'file') or nil,
    location_line = is_file and location.format(ctx, 'line') or nil,
    location_position = is_file and location.format(ctx, 'position') or nil,
    selection = selection.text(ctx),
  }
end

local function render_string(template, data)
  local ok = true
  local rendered = template:gsub('{([%w_]+)}', function(key)
    local value = data[key]
    if value == nil then
      ok = false
      return ''
    end
    return tostring(value)
  end)

  if not ok or rendered == '' then
    return nil
  end
  return rendered
end

local function render_template(name, ctx, data)
  local template = config.get().templates[name]
  if type(template) == 'function' then
    local ok, value = pcall(template, data, ctx)
    return ok and value or nil
  end
  if type(template) ~= 'string' then
    return nil
  end
  return render_string(template, data)
end

function M.render(opts)
  opts = type(opts) == 'string' and { msg = opts } or opts or {}
  local ctx = context.current()
  local data = vars(ctx)
  local msg = opts.msg or ''

  if opts.this ~= false then
    if context.is_file(ctx.buf) then
      msg = msg:gsub('{this}', '{position}')
    elseif msg:find('{this}', 1, true) then
      msg = msg:gsub('{this}', 'this') .. '\n\n{selection}'
    end
  end

  local ok = true
  msg = msg:gsub('{([%w_]+)}', function(key)
    local value = render_template(key, ctx, data)
    if not value then
      value = data[key]
    end
    if value == nil then
      ok = false
      return ''
    end
    return tostring(value)
  end)

  if not ok or msg == '' then
    return nil
  end
  return msg
end

return M
