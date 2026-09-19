# grokbot-build-relay

**Talk to Grok Build on your PC through Grok Bot — no babysitting the TUI.**

A tiny headless bridge so an assistant with Shell access on your machine can drive [Grok Build](https://x.ai) locally. You send prompts from Grok Bot (or Cursor, or any agent with terminal access); Build edits files in a project folder on your laptop. You review the results in your editor, Godot, or git.

## What it does

| Command | What happens |
|---------|--------------|
| `prompt` | Start a new Build session: `agent -p` with plain-text output |
| `continue` | Follow up in the same cwd: `agent -c -p` |
| `resume` | Pick up a session by id: `agent --resume <id> -p` |
| `which` | Show where `agent` was found and its version |

Headless only — no live TUI attach, no named pipes, no experimental ACP plumbing. Just the reliable path that works.

## Prerequisites

1. **Grok Build CLI** installed and logged in on the PC you want to drive.
2. **Grok Bot** (or Cursor, or another assistant) with **Shell** access to that same machine.

The bridge looks for the CLI at `%USERPROFILE%\.grok\bin\agent.exe`, then falls back to `agent` or `grok` on your PATH.

## Install

Clone anywhere — no build step:

```powershell
git clone https://github.com/sec-knight/grokbot-build-relay.git C:\path\to\grokbot-build-relay
```

Optional: point Build at a default project folder:

```powershell
setx GROK_BRIDGE_CWD "C:\path\to\your-project"
```

If unset, the bridge uses `./workspace` under the clone (created automatically).

## Manual test (on your PC)

Open PowerShell on the machine where Grok Build is installed:

```powershell
cd C:\path\to\grokbot-build-relay

# Confirm the CLI is reachable
.\scripts\bridge.cmd which

# First prompt (creates/uses the workspace or GROK_BRIDGE_CWD)
.\scripts\bridge.cmd prompt "List the files in this directory"

# Follow-up in the same folder
.\scripts\bridge.cmd continue "Create a hello.txt with a short greeting"
```

You should see only Build's reply on stdout. On failure, the script exits nonzero.

Target a specific project for one call:

```powershell
.\scripts\bridge.ps1 prompt "Add a README" -Cwd "C:\path\to\your-project"
```

## How Grok Bot uses it

Grok Bot runs Shell on **your** machine (via `machineId`). Point it at this repo and your project cwd.

**Check the CLI:**

```text
cd C:\path\to\grokbot-build-relay && .\scripts\bridge.cmd which
```

**Start work in a project:**

```text
cd C:\path\to\grokbot-build-relay && .\scripts\bridge.ps1 prompt "Scaffold a minimal REST API" -Cwd "C:\path\to\your-project"
```

**Multi-turn (same folder, same session context):**

```text
cd C:\path\to\grokbot-build-relay && .\scripts\bridge.ps1 continue "Add unit tests for the handlers" -Cwd "C:\path\to\your-project"
```

**Resume a saved session:**

```text
cd C:\path\to\grokbot-build-relay && .\scripts\bridge.ps1 resume SESSION_ID_HERE "Fix the failing test" -Cwd "C:\path\to\your-project"
```

Replace `SESSION_ID_HERE` with the id Build printed when the session was created.

## Notes

- **Headless** means there is no live TUI window to watch. Build still reads and writes files in the cwd you choose.
- **Review locally** — open the project in your editor, run your game engine, or `git diff` when Build is done.
- **`--always-approve` is not passed** by default. Approve tool use in your normal Grok Build workflow, or add flags yourself if you need unattended runs.
- **Windows only** for v1 (`bridge.ps1` targets PowerShell 5.1+; `bridge.cmd` is a thin shim).

## Scripts

```
scripts/
  bridge.ps1   # main relay
  bridge.cmd   # calls bridge.ps1 (use this from cmd or Grok Bot Shell)
```

## License

MIT — see [LICENSE](LICENSE).
