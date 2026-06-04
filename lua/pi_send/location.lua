local M = {}

local function relpath(cwd, path)
  local ok, rel = pcall(vim.fs.relpath, cwd, path)
  if ok and rel and rel ~= '' and rel ~= '.' then
    return rel
  end
  return path
end

function M.format(ctx, kind)
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

return M
