local config = require('pi_send.config')
local notify = require('pi_send.notify').notify
local picker = require('pi_send.picker')
local render = require('pi_send.render')
local tmux = require('pi_send.tmux')

local M = {}

M.render = render.render
M.panes = tmux.panes
M.setup = config.setup

function M.send(opts)
  local msg = M.render(opts)
  if not msg then
    notify('Nothing to send', vim.log.levels.WARN)
    return
  end

  picker.choose(function(pane)
    if not pane then
      return
    end

    local ok, err = pcall(tmux.send, pane, msg)
    if not ok then
      notify(err, vim.log.levels.ERROR)
      return
    end

    notify(string.format('Sent message to tmux pane %s:%s', pane.session, pane.window_index))
  end)
end

return M
