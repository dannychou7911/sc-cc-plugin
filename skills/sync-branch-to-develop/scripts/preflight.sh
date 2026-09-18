#!/usr/bin/env bash
# Preflight checks for cherry-picking a branch from one long-lived line to the other.
# Read-only: inspects state and reports, never mutates the repo.
#
# Usage: preflight.sh [source-branch] [stable-line] [integration-line]
#   source-branch    defaults to the current branch
#   stable-line      defaults to master, then main
#   integration-line defaults to develop, then dev

set -uo pipefail

BLOCKERS=0
note() { printf '%s\n' "$*"; }
block() { printf 'BLOCKER: %s\n' "$*"; BLOCKERS=$((BLOCKERS + 1)); }
has_branch() { git rev-parse --verify --quiet "refs/heads/$1" >/dev/null; }

git rev-parse --git-dir >/dev/null 2>&1 || { note "BLOCKER: not inside a git repository"; exit 2; }

SOURCE="${1:-$(git rev-parse --abbrev-ref HEAD)}"

# --- detect the two long-lived lines -------------------------------------------
# Never assume the names: projects use master or main, develop or dev. Ambiguity
# is reported rather than guessed, because picking the wrong line silently
# produces a branch based on the wrong history.
detect_line() {
  local found=()
  for name in "$@"; do
    has_branch "${name}" && found+=("${name}")
  done
  case "${#found[@]}" in
    0) printf '\n' ;;
    1) printf '%s\n' "${found[0]}" ;;
    *) printf 'AMBIGUOUS:%s\n' "$(IFS=,; echo "${found[*]}")" ;;
  esac
}

STABLE="${2:-$(detect_line stable master main)}"
INTEGRATION="${3:-$(detect_line integration develop dev)}"

for pair in "stable line:${STABLE}" "integration line:${INTEGRATION}"; do
  label="${pair%%:*}"; value="${pair#*:}"
  case "${value}" in
    "")            block "no ${label} found (looked for master/main and develop/dev) — pass it explicitly" ;;
    AMBIGUOUS:*)   block "multiple candidates for the ${label}: ${value#AMBIGUOUS:} — ask the user which one to use" ;;
  esac
done

if [ "${BLOCKERS}" -gt 0 ]; then
  note "RESULT: ${BLOCKERS} blocker(s) — cannot determine the two lines."
  exit 2
fi

TARGET="dev/${SOURCE}"

note "stable line      : ${STABLE}"
note "integration line : ${INTEGRATION}"
note "source branch    : ${SOURCE}"
note "target branch    : ${TARGET}"
note ""

# --- the project must actually maintain two lines ------------------------------
if [ "$(git rev-parse "${STABLE}")" = "$(git rev-parse "${INTEGRATION}")" ]; then
  block "'${STABLE}' and '${INTEGRATION}' point at the same commit — this project is not maintaining two separate lines, so this workflow does not apply"
  note "RESULT: ${BLOCKERS} blocker(s) — precondition not met."
  exit 2
fi

has_branch "${SOURCE}" || { block "source branch '${SOURCE}' does not exist locally"; exit 2; }

# --- working tree --------------------------------------------------------------
if [ -n "$(git status --porcelain)" ]; then
  block "working tree is not clean — uncommitted changes would follow you across branches"
  git status --short
  note ""
fi

if [ -e "$(git rev-parse --git-dir)/CHERRY_PICK_HEAD" ]; then
  block "a cherry-pick is already in progress; resolve or abort it first"
fi

# --- commit range --------------------------------------------------------------
BASE="$(git merge-base "${STABLE}" "${SOURCE}")"
note "merge-base ${STABLE}..${SOURCE} : ${BASE}"
note ""

COUNT="$(git rev-list --count "${BASE}..${SOURCE}")"
note "commits to cherry-pick (${COUNT}), oldest first:"
git log --oneline --reverse "${BASE}..${SOURCE}"
note ""

if [ "${COUNT}" -eq 0 ]; then
  block "nothing to cherry-pick — '${SOURCE}' has no commits beyond its merge-base with ${STABLE} (it has most likely already been merged in)"
fi

# --- target branch already present ---------------------------------------------
if has_branch "${TARGET}"; then
  block "target branch '${TARGET}' already exists — ask the user before touching it"
  note "commits already on ${TARGET} (vs ${INTEGRATION}):"
  if [ -z "$(git rev-list "${INTEGRATION}..${TARGET}")" ]; then
    note "  (none — ${TARGET} carries nothing beyond ${INTEGRATION}, so it has probably already been merged in)"
  else
    git log --oneline "${INTEGRATION}..${TARGET}"
  fi
  note ""
  if [ "${COUNT}" -gt 0 ]; then
    # Limit the comparison to BASE..SOURCE: without the third argument git cherry
    # walks the whole history and reports commits that are long since on the
    # stable line as if they still needed picking.
    note "of those ${COUNT}, the ones not yet on ${TARGET} (matched by patch-id):"
    git cherry -v "${TARGET}" "${SOURCE}" "${BASE}" | grep '^+' \
      || note "  (none — every commit in range already has an equivalent there)"
    note ""
  fi
fi

# --- merge commits -------------------------------------------------------------
if [ -n "$(git rev-list --merges "${BASE}..${SOURCE}")" ]; then
  block "range contains merge commits — cherry-pick needs -m and the user must decide"
  git log --oneline --merges "${BASE}..${SOURCE}"
  note ""
fi

# --- standing differences between the two lines --------------------------------
# These are the files where conflicts are most likely, and where a conflict is
# usually a line difference rather than a real clash of intent.
note "files that already differ between ${STABLE} and ${INTEGRATION} (likely conflict sites):"
LINE_DIFF="$(git diff --stat "${STABLE}" "${INTEGRATION}")"
if [ -z "${LINE_DIFF}" ]; then
  note "  (no file-level differences — the two lines diverge only in history, so conflicts are unlikely)"
else
  printf '%s\n' "${LINE_DIFF}" | sed 's/^/  /'
fi
note ""

if [ "${BLOCKERS}" -gt 0 ]; then
  note "RESULT: ${BLOCKERS} blocker(s) — stop and consult the user."
  exit 2
fi

note "RESULT: clear to proceed."
