#!/usr/bin/env bash
# Claude Code PostToolUse hook for the ExitPlanMode tool.
# Uploads the most recent plan file in ~/.claude/plans/ to Lark/Feishu Docs
# via lark-cli, and prints the doc URL on stderr so it surfaces in the session.

set -uo pipefail

LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/plan-to-lark.log"
PLAN_DIR="${HOME}/.claude/plans"
mkdir -p "${LOG_DIR}"

ts() { date "+%Y-%m-%d %H:%M:%S"; }
log() { printf '[%s] %s\n' "$(ts)" "$*" >> "${LOG_FILE}"; }

# Drain stdin (hook payload not needed here) so the parent doesn't block.
cat >/dev/null 2>&1 || true

if ! command -v lark-cli >/dev/null 2>&1; then
  log "lark-cli not found in PATH, skipping"
  printf 'plan-to-lark: lark-cli not installed (npm i -g @larksuite/cli)\n' >&2
  exit 0
fi

PLAN_FILE="$(ls -t "${PLAN_DIR}"/*.md 2>/dev/null | head -n 1)"
if [ -z "${PLAN_FILE:-}" ] || [ ! -f "${PLAN_FILE}" ]; then
  log "no plan file found in ${PLAN_DIR}, skipping"
  exit 0
fi

TITLE="$(grep -m1 -E '^#[[:space:]]+' "${PLAN_FILE}" | sed -E 's/^#+[[:space:]]+//')"
if [ -z "${TITLE}" ]; then
  TITLE="$(basename "${PLAN_FILE}" .md)"
fi
TITLE="[Plan] ${TITLE}"

log "creating Lark doc from ${PLAN_FILE} — title: ${TITLE}"

RESPONSE="$(lark-cli docs +create --title "${TITLE}" --markdown - < "${PLAN_FILE}" 2>&1)"
EXIT=$?
log "lark-cli exit=${EXIT} response=${RESPONSE}"

if [ ${EXIT} -ne 0 ]; then
  printf 'plan-to-lark: failed (exit %d). See %s\n' "${EXIT}" "${LOG_FILE}" >&2
  exit 0
fi

DOC_URL="$(printf '%s' "${RESPONSE}" | sed -nE 's/.*"doc_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)"
if [ -n "${DOC_URL}" ]; then
  printf '📄 Plan uploaded to Lark: %s\n' "${DOC_URL}" >&2
  log "doc_url=${DOC_URL}"
else
  printf 'plan-to-lark: created but no doc_url parsed; see %s\n' "${LOG_FILE}" >&2
fi

exit 0
