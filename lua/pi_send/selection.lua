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
  }
end

function M.text(ctx)
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

return M
