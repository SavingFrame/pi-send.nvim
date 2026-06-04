# pi-send.nvim

Local Neovim prototype for sending buffer context to a `pi` agent running in a tmux pane.

This is a copied prototype from the local Neovim config. It is not production-ready and should not be published yet.

## Current behavior

- Finds tmux panes in the current tmux session using `tmux list-panes`.
- Treats a pane as a `pi` target when the pane process tree contains a `pi` process.
- If multiple panes match, prompts with `vim.ui.select`.
- Sends text with tmux buffers:
  - `tmux load-buffer -b <buffer> -`
  - `tmux paste-buffer -b <buffer> -d -r -t <pane_id>`
- Supports templates:
  - `{this}`
  - `{file}`
  - `{line}`
  - `{position}`
  - `{selection}`

## Prototype keymaps

These keymaps are still kept in the local Neovim config, not installed by this plugin:

```lua
vim.keymap.set('n', '<leader>aa', function()
  require('pi_send').send({ msg = '{this}' })
end, { desc = 'Send This to Pi' })

vim.keymap.set('x', '<leader>aa', function()
  require('pi_send').send({ msg = '{this}' })
end, { desc = 'Send Visual Selection to Pi' })

vim.keymap.set('x', '<leader>at', function()
  require('pi_send').send({ msg = '{selection}' })
end, { desc = 'Send Visual Selection to Pi' })

vim.keymap.set('n', '<leader>af', function()
  require('pi_send').send({ msg = '{file}' })
end, { desc = 'Send File to Pi' })
```

## Local config status

The original local config still has `lua/pi_send.lua`, so it continues to work without changes.

Later, after adding this plugin to the plugin manager, remove the local `lua/pi_send.lua` file or update the runtime path so `require('pi_send')` resolves to this plugin.

## Status

See [BACKLOG.md](./BACKLOG.md) before refactoring or preparing this for publication.
