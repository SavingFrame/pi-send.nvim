local M = {}

local tmux_format = table.concat({
  '#{pane_id}',
  '#{session_name}',
  '#{window_index}',
  '#{window_name}',
  '#{pane_index}',
  '#{pane_title}',
  '#{pane_current_command}',
  '#{pane_current_path}',
}, '\t')

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'pi-send' })
end

local function system(cmd, opts)
  opts = opts or {}
  local obj = vim.system(cmd, opts):wait()
  if obj.code ~= 0 then
    local err = vim.trim(obj.stderr or '')
    error(err ~= '' and err or ('command failed: ' .. table.concat(cmd, ' ')))
  end
  return obj.stdout or ''
end

local function is_file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.bo[buf].buflisted
    and vim.tbl_contains({ '', 'help' }, vim.bo[buf].buftype)
    and name ~= ''
    and vim.fn.filereadable(name) == 1
end

local function relpath(cwd, path)
  local ok, rel = pcall(vim.fs.relpath, cwd, path)
  if ok and rel and rel ~= '' and rel ~= '.' then
    return rel
  end
  return path
end

local function visual_mode()
  local mode = vim.fn.mode()
  if not (mode:match('^[vV]$') or mode == '\22') then
    return nil
  end
  return mode == 'V' and 'line' or mode == 'v' and 'char' or 'block', mode
end

local function get_selection(buf)
  local kind, mode = visual_mode()
  if not kind then
    return nil
  end

  vim.cmd('normal! ' .. mode)

  local from = vim.api.nvim_buf_get_mark(buf, '<')
  local to = vim.api.nvim_buf_get_mark(buf, '>')
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end

  vim.fn.feedkeys('gv', 'nx')

  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind,
  }
end

local function location(ctx, kind)
  local name = relpath(ctx.cwd, vim.api.nvim_buf_get_name(ctx.buf))
  local ret = '@' .. name
  if kind == 'file' then
    return ret
  end

  local from = ctx.range and ctx.range.from or { ctx.row, ctx.col - 1 }
  local to = ctx.range and ctx.range.to or nil

  if kind == 'line' or (ctx.range and ctx.range.kind == 'line') then
    ret = ret .. ':L' .. from[1]
    if to and from[1] ~= to[1] then
      ret = ret .. '-L' .. to[1]
    end
    return ret
  end

  ret = ret .. ':L' .. from[1] .. ':C' .. (from[2] + 1)
  if to and from[1] == to[1] and from[2] ~= to[2] then
    ret = ret .. '-C' .. (to[2] + 1)
  elseif to and from[1] ~= to[1] then
    ret = ret .. '-L' .. to[1] .. ':C' .. (to[2] + 1)
  end
  return ret
end

local function selection_text(ctx)
  local range = ctx.range
  if not range then
    return nil
  end

  local from, to = range.from, range.to
  if range.kind == 'line' then
    return table.concat(vim.api.nvim_buf_get_lines(ctx.buf, from[1] - 1, to[1], false), '\n')
  end

  if range.kind == 'block' then
    local start_col = math.min(from[2], to[2])
    local end_col = math.max(from[2], to[2])
    local lines = vim.api.nvim_buf_get_lines(ctx.buf, from[1] - 1, to[1], false)
    for i, line in ipairs(lines) do
      lines[i] = string.sub(line, start_col + 1, end_col + 1)
    end
    return table.concat(lines, '\n')
  end

  local lines = vim.api.nvim_buf_get_text(ctx.buf, from[1] - 1, from[2], to[1] - 1, to[2] + 1, {})
  return table.concat(lines, '\n')
end

local function context()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    win = win,
    buf = buf,
    cwd = vim.fs.normalize(vim.fn.getcwd(win)),
    row = cursor[1],
    col = cursor[2] + 1,
    range = get_selection(buf),
  }
end

function M.render(opts)
  opts = type(opts) == 'string' and { msg = opts } or opts or {}
  local ctx = context()
  local msg = opts.msg or ''

  if opts.this ~= false then
    if is_file(ctx.buf) then
      msg = msg:gsub('{this}', '{position}')
    elseif msg:find('{this}', 1, true) then
      msg = msg:gsub('{this}', 'this') .. '\n\n{selection}'
    end
  end

  local replacements = {
    file = function()
      return is_file(ctx.buf) and location(ctx, 'file') or nil
    end,
    line = function()
      return is_file(ctx.buf) and location(ctx, 'line') or nil
    end,
    position = function()
      return is_file(ctx.buf) and location(ctx, 'position') or nil
    end,
    selection = function()
      return selection_text(ctx)
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

function M.panes()
  local out = system({ 'tmux', 'list-panes', '-a', '-F', tmux_format })
  local panes = {}

  for line in vim.gsplit(out, '\n', { plain = true, trimempty = true }) do
    local parts = vim.split(line, '\t', { plain = true })
    local pane = {
      id = parts[1],
      session = parts[2],
      window_index = parts[3],
      window = parts[4],
      pane_index = parts[5],
      title = parts[6] or '',
      command = parts[7] or '',
      cwd = parts[8] or '',
    }
    local title = pane.title:lower()
    local command = pane.command:lower()
    if command == 'pi' or title:find('pi', 1, true) then
      panes[#panes + 1] = pane
    end
  end

  return panes
end

local function choose_pane(cb)
  local ok, panes = pcall(M.panes)
  if not ok then
    notify(panes, vim.log.levels.ERROR)
    return
  end

  if #panes == 0 then
    notify('No tmux panes with pi found', vim.log.levels.WARN)
    return
  end

  if #panes == 1 then
    cb(panes[1])
    return
  end

  local function label(pane)
    local title = pane.title ~= '' and pane.title or pane.command
    return string.format('[%s:%s] %s', pane.session, pane.window_index, title)
  end

  vim.ui.select(panes, {
    prompt = 'Select pi pane:',
    format_item = label,
    snacks = {
      format = function(pane)
        local title = pane.title ~= '' and pane.title or pane.command
        return {
          { '[' .. pane.session .. ':' .. pane.window_index .. '] ', 'Comment' },
          { title, 'Normal' },
        }
      end,
    },
  }, cb)
end

function M.send(opts)
  local msg = M.render(opts)
  if not msg then
    notify('Nothing to send', vim.log.levels.WARN)
    return
  end

  choose_pane(function(pane)
    if not pane then
      return
    end

    local buffer = 'pi-send-' .. pane.id
    local ok, err = pcall(function()
      system({ 'tmux', 'load-buffer', '-b', buffer, '-' }, { stdin = msg .. '\n' })
      system({ 'tmux', 'paste-buffer', '-b', buffer, '-d', '-r', '-t', pane.id })
    end)

    if not ok then
      notify(err, vim.log.levels.ERROR)
    end
  end)
end

return M
