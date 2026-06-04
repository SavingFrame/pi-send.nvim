# pi-send.nvim

Send Neovim context to a [`pi`](https://github.com/earendil-works/pi-coding-agent) coding agent running in a tmux pane.

`pi-send.nvim` turns file locations, cursor positions, and visual selections into short prompts, then pastes them into the matching `pi` pane through tmux buffers. It is meant for a local workflow where Neovim and `pi` share the same tmux server.

## Requirements

- Neovim 0.10 or newer
- tmux
- `pi` running in a tmux pane
- `ps`, used to detect whether a tmux pane process tree contains `pi`

## Installation

### vim.pack, Neovim 0.12+

```lua
vim.pack.add({
  'https://github.com/SavingFrame/pi-send.nvim',
})

require('pi_send').setup()

vim.keymap.set({ 'n', 'x' }, '<leader>aa', function()
  require('pi_send').send({ msg = '{this}' })
end, { desc = 'Send context to pi' })

vim.keymap.set('n', '<leader>af', function()
  require('pi_send').send({ msg = '{file}' })
end, { desc = 'Send file to pi' })

vim.keymap.set('n', '<leader>al', function()
  require('pi_send').send({ msg = '{line}' })
end, { desc = 'Send line to pi' })

vim.keymap.set('n', '<leader>ap', function()
  require('pi_send').send({ msg = '{position}' })
end, { desc = 'Send cursor position to pi' })

vim.keymap.set('x', '<leader>as', function()
  require('pi_send').send({ msg = '{selection}' })
end, { desc = 'Send selection to pi' })
```

### lazy.nvim

```lua
{
  'SavingFrame/pi-send.nvim',
  main = 'pi_send',
  opts = {},
  keys = {
    {
      '<leader>aa',
      function()
        require('pi_send').send({ msg = '{this}' })
      end,
      mode = { 'n', 'x' },
      desc = 'Send context to pi',
    },
    {
      '<leader>af',
      function()
        require('pi_send').send({ msg = '{file}' })
      end,
      desc = 'Send file to pi',
    },
    {
      '<leader>al',
      function()
        require('pi_send').send({ msg = '{line}' })
      end,
      desc = 'Send line to pi',
    },
    {
      '<leader>ap',
      function()
        require('pi_send').send({ msg = '{position}' })
      end,
      desc = 'Send cursor position to pi',
    },
    {
      '<leader>as',
      function()
        require('pi_send').send({ msg = '{selection}' })
      end,
      mode = 'x',
      desc = 'Send selection to pi',
    },
  },
}
```

The plugin does not create default keymaps. Use the mappings above or add the ones that fit your workflow.

## Setup

`setup()` is optional. These are the defaults:

```lua
require('pi_send').setup({
  tmux = {
    -- Only search panes in the current tmux session.
    -- Set to false to search all sessions.
    current_session_only = true,
  },
  send = {
    -- Append a newline after the rendered message before pasting it into tmux.
    append_newline = true,
  },
  templates = {
    -- Customize how placeholders render.
    file = '@{file}',
    line = '@{file}:L{line}',
    position = '@{file}:L{line}:C{column}',
    selection = '{selection}',
  },
})
```

## Placeholders

`send()` renders placeholders in `msg` before sending.

| Placeholder | Meaning |
| --- | --- |
| `{this}` | Smart context. In a file buffer it renders as `{position}`. In a non-file visual selection it sends `this` followed by the selected text. |
| `{file}` | Relative file path when the current buffer is a readable file. |
| `{line}` | Current line location using the configured `line` template. |
| `{position}` | Current line and column location using the configured `position` template. |
| `{selection}` | Current visual selection text. |
| `{location_file}` | Built in file location, formatted as `@path/to/file`. |
| `{location_line}` | Built in line location, formatted as `@path/to/file:L3`. |
| `{location_position}` | Built in position location, formatted as `@path/to/file:L3:C1`. |

Template values may also be functions:

```lua
require('pi_send').setup({
  templates = {
    position = function(data)
      return string.format('@%s:L%s:C%s', data.file, data.line, data.column)
    end,
  },
})
```

Function templates receive `(data, ctx)`. Return `nil` to make the placeholder fail to render.
