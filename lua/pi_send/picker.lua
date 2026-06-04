local notify = require('pi_send.notify').notify
local tmux = require('pi_send.tmux')

local M = {}

local function label(pane)
  local title = pane.title ~= '' and pane.title or pane.command
  return string.format('[%s:%s] %s', pane.session, pane.window_index, title)
end

function M.choose(cb)
  local ok, panes = pcall(tmux.panes)
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

return M
