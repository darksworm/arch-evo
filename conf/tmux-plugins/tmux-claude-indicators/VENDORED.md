# Vendored plugin

Upstream: https://github.com/itsdevcoffee/tmux-claude-indicators (MIT)
Vendored at upstream commit: 2674e858a3dbffd363636800a9a4429eee1080fc

Vendored rather than TPM-managed because of the local patch below; a
`prefix + U` would otherwise overwrite it on every plugin update.

## Local patches

**Hooks aborted when a tmux option was unset.**
`tmux show-option` / `show-window-option` without `-q` exit 1 when the
option does not exist. The hooks run under `set -euo pipefail`, so the
assignment aborted the script. Claude Code surfaced this as
`PreToolUse:Bash hook error / Failed with non-blocking status code:
No stderr output` on every single tool call — @claude-needs-animator is
unset with `-u` after each animator start, so it was missing on nearly
every invocation, and the hooks' `exec >/dev/null 2>&1` left no message
to explain it.

Added `-q` and a `|| true` guard in:
- `hooks/user-prompt.sh` (the PreToolUse/UserPromptSubmit hook — the actual failure)
- `hooks/notification.sh` (same bug, also under `set -e`, on permission-prompt escalation)
- `bin/claude-thinking-animator` (same lookup in the animation loop; latent, no `set -e`)

## Re-syncing with upstream

Diff the vendored tree against a fresh upstream checkout, re-apply the
patches above, and bump the commit hash in this file.
