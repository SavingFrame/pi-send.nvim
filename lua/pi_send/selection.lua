local M = {}

local function visual_mode()
  local mode = vim.fn.mode()
  if not (mode:match('^[vV]$') or mode == '\22') then
    return nil
  end
  return mode == 'V' and 'line' or mode == 'v' and 'char' or 'block', mode
end

function M.range(buf)
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
    mode = mode,
  }
end

local function getregion_text(buf, range)
  if vim.fn.exists('*getregion') ~= 1 then
    return nil
  end

  local from = { buf, range.from[1], range.from[2] + 1, 0 }
  local to = { buf, range.to[1], range.to[2] + 1, 0 }
  local ok, lines = pcall(vim.fn.getregion, from, to, {
    type = range.mode or (range.kind == 'line' and 'V' or range.kind == 'block' and '\22' or 'v'),
    exclusive = false,
  })
  if not ok or vim.tbl_isempty(lines) then
    return nil
  end
  return table.concat(lines, '\n')
end

local function legacy_text(ctx)
  local from, to = ctx.range.from, ctx.range.to
  if ctx.range.kind == 'line' then
    return table.concat(vim.api.nvim_buf_get_lines(ctx.buf, from[1] - 1, to[1], false), '\n')
  end

  if ctx.range.kind == 'block' then
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

function M.text(ctx)
  local range = ctx.range
  if not range then
    return nil
  end

  return getregion_text(ctx.buf, range) or legacy_text(ctx)
end

return M
