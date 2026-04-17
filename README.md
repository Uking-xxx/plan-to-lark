# plan-to-lark

A Claude Code plugin that **automatically uploads your plan-mode plans to Lark/Feishu Docs**. Whenever Claude calls `ExitPlanMode` (i.e. submits a plan for your approval), this plugin grabs the latest plan file from `~/.claude/plans/` and creates a Lark doc via the Lark CLI. The doc URL is printed back into your session.

## Prerequisites

Each user needs the following on their own machine:

1. **Install Lark CLI**
   ```bash
   npm i -g @larksuite/cli
   ```
2. **Log in to your Lark/Feishu account** (OAuth, one-time per machine)
   ```bash
   lark-cli auth login
   ```
   Verify with `lark-cli auth status`. The token must include scope `docx:document:create`.

## Install

### Option A — Subscribe to the marketplace (recommended)

```text
/plugin marketplace add https://github.com/Uking-xxx/plan-to-lark
/plugin install plan-to-lark@plan-to-lark
```

### Option B — Local install

```bash
git clone https://github.com/Uking-xxx/plan-to-lark ~/projects/plan-to-lark
```
Then in Claude Code:
```text
/plugin install ~/projects/plan-to-lark
```

After installing, **restart your Claude Code session** so the hook is registered.

## How it works

| Trigger | `PostToolUse` event with `matcher: "ExitPlanMode"` |
|---|---|
| Action | Reads the newest `*.md` in `~/.claude/plans/`, takes the first H1 as the title, pipes the content to `lark-cli docs +create --markdown -` |
| Output | Doc URL is printed to stderr (visible in the Claude session) and appended to `~/.claude/logs/plan-to-lark.log` |
| On error | Logs and exits 0 — never blocks Claude |

## Caveats

- Triggers when the plan is **submitted**, not after you approve it. Even a rejected plan will be uploaded.
- The plan file is identified by mtime in `~/.claude/plans/`; multiple concurrent sessions could race.
- Doc title prefix is hardcoded to `[Plan] `. Edit `scripts/plan-to-lark.sh` to customize.
- Requires `lark-cli` reachable on `$PATH` of the Claude Code process.

## Uninstall

```text
/plugin uninstall plan-to-lark
```

If you previously added the same hook manually to `~/.claude/settings.json`, remove it to avoid duplicate uploads.

## License

MIT
