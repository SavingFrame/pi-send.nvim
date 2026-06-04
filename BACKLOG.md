# Backlog

Known production-readiness and refactor work. Do not implement these until the project is ready to move beyond the copied prototype.

## Plugin API and configuration

- Add a public `setup()` function.
- Define defaults and user config for tmux target detection, picker behavior, templates, notifications, and send behavior.
- Decide the published module/plugin name. `pi_send.lua` is too local and generic for a published plugin.
- Decide whether the plugin should define default keymaps, expose mapping helpers, or only document user keymaps.

## Commands and user interface

- Add user commands such as `:PiSend`.
- Decide command variants for `{this}`, `{file}`, `{line}`, `{position}`, and `{selection}`.
- Improve picker behavior and make picker formatting configurable.
- Keep the current simple display format unless a new UI design is chosen: `[session:window_index] title`.

## Tmux integration

- Tighten pane detection. Current detection is too loose because it accepts any pane where `pane_title` contains `pi`.
- Decide reliable matching rules using `pane_current_command`, `pane_title`, explicit pane IDs, or configured sessions/windows.
- Handle missing tmux, detached sessions, no server running, and command failures cleanly.
- Preserve Sidekick-style sending through tmux buffers:
  - `tmux load-buffer -b <buffer> -`
  - `tmux paste-buffer -b <buffer> -d -r -t <pane_id>`

## Architecture

Split the current single-file prototype into focused modules:

- Rendering/template expansion.
- Context collection.
- Location formatting.
- Selection extraction.
- Tmux pane discovery and sending.
- Picker/pane selection.
- Public API.

## Context and selection correctness

- Improve visual selection handling for multibyte text. The current implementation is byte-based.
- Review characterwise, linewise, and blockwise visual selection behavior.
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
