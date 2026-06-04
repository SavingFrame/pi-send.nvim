# Backlog

Known production-readiness and refactor work. Do not implement these until the project is ready to move beyond the copied prototype.

## Plugin API and configuration

- Expand `setup()` only when a concrete user-facing option is needed. Current config covers `tmux.current_session_only`, `send.append_newline`, and templates.
- Decide the published module/plugin name. `pi_send.lua` is too local and generic for a published plugin.
- Decide whether the plugin should define default keymaps, expose mapping helpers, or only document user keymaps.

## Commands and user interface

- Add user commands such as `:PiSend`.
- Decide command variants for `{this}`, `{file}`, `{line}`, `{position}`, and `{selection}`.
- Improve picker behavior if a concrete UX problem appears. Keep picker formatting hardcoded for now.
- Keep the current simple display format unless a new UI design is chosen: `[session:window_index] title`.

## Tmux integration

- Handle missing tmux, detached sessions, no server running, and command failures cleanly.
- Preserve Sidekick-style sending through tmux buffers:
  - `tmux load-buffer -b <buffer> -`
  - `tmux paste-buffer -b <buffer> -d -r -t <pane_id>`

## Context and selection correctness

- Add regression tests for multibyte visual selections. Selection extraction now uses `getregion()` when available.
- Review characterwise, linewise, and blockwise visual selection behavior against real visual-mode edge cases.
- Add edge-case handling for unnamed buffers, non-file buffers, help buffers, terminal buffers, and empty selections.
- Keep current location format: `@file:L3:C1`.

## Async and performance

- Replace blocking `vim.system(...):wait()` calls where appropriate.
- Decide where async behavior is needed and how errors should be surfaced.
- Avoid blocking the UI during pane discovery and tmux send operations.

## Tests

- Add tests for template rendering.
- Add tests for location formatting.
- Add tests for selection extraction, including multibyte text.
- Add tests for tmux pane parsing and filtering.
- Add tests for error handling paths.

## Documentation and release prep

- Add install docs for common plugin managers.
- Add usage examples.
- Document requirements: Neovim version, tmux, and `pi` running in a tmux pane.
- Document supported templates.
- Add development notes.
- Add release checklist before publishing.
