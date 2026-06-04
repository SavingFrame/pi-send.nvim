local system = require('pi_send.system')

local M = {}

local tmux_format = table.concat({
  '#{session_id}',
  '#{pane_id}',
  '#{pane_pid}',
  '#{session_name}',
  '#{window_index}',
  '#{window_name}',
  '#{pane_index}',
  '#{pane_title}',
  '#{pane_current_command}',
  '#{pane_current_path}',
}, '\t')

local function proc_basename(cmd)
  local exe = cmd:match('^%S+') or ''
  return vim.fn.fnamemodify(exe, ':t')
end

local function is_pi_proc(proc)
  return proc_basename(proc.cmd) == 'pi'
end

local function process_tree()
  if vim.fn.executable('ps') ~= 1 then
    return { procs = {}, children = {} }
  end

  local cmd = { 'ps' }
  if (vim.env.USER or '') ~= '' then
    vim.list_extend(cmd, { '-u', vim.env.USER })
  end
  vim.list_extend(cmd, { '-ww', '-o', 'pid,ppid,args' })

  local ok, out = pcall(system.run, cmd)
  if not ok then
    return { procs = {}, children = {} }
  end

  local procs = {}
  local children = {}
  for line in vim.gsplit(out, '\n', { plain = true, trimempty = true }) do
    local pid, ppid, args = line:match('^%s*(%d+)%s+(%d+)%s+(.*)$')
    if pid and ppid and args and args ~= 'args' and args ~= 'COMMAND' then
      pid = tonumber(pid)
      ppid = tonumber(ppid)
      procs[pid] = { pid = pid, ppid = ppid, cmd = args }
      children[ppid] = children[ppid] or {}
      children[ppid][#children[ppid] + 1] = pid
    end
  end

  return { procs = procs, children = children }
end

local function pane_has_pi(pane, tree)
  local todo = { pane.pid }
  local seen = {}
  while #todo > 0 do
    local pid = table.remove(todo, 1)
    if not seen[pid] then
      seen[pid] = true
      local proc = tree.procs[pid]
      if proc and is_pi_proc(proc) then
        return true
      end
      vim.list_extend(todo, tree.children[pid] or {})
    end
  end
  return false
end

function M.panes()
  local out = system.run({ 'tmux', 'list-panes', '-F', tmux_format })
  local panes = {}
  local tree = process_tree()

  for line in vim.gsplit(out, '\n', { plain = true, trimempty = true }) do
    local parts = vim.split(line, '\t', { plain = true })
    local pid = tonumber(parts[3] or '')
    local pane = {
      session_id = parts[1],
      id = parts[2],
      pid = pid,
      session = parts[4],
      window_index = parts[5],
      window = parts[6],
      pane_index = parts[7],
      title = parts[8] or '',
      command = parts[9] or '',
      cwd = parts[10] or '',
    }
    if pane.pid and pane_has_pi(pane, tree) then
      panes[#panes + 1] = pane
    end
  end

  return panes
end

function M.send(pane, msg)
  local buffer = 'pi-send-' .. pane.id
  system.run({ 'tmux', 'load-buffer', '-b', buffer, '-' }, { stdin = msg .. '\n' })
  system.run({ 'tmux', 'paste-buffer', '-b', buffer, '-d', '-r', '-t', pane.id })
end

return M
