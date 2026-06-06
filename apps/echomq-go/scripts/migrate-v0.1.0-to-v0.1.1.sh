#!/usr/bin/env bash
#
# migrate-v0.1.0-to-v0.1.1.sh
#
# Scans a Go codebase for echomq-go v0.1.0 handler-signature patterns that will
# break under v0.1.1 (see MIGRATION.md for full context).
#
# v0.1.0 handler signature:    func(*echomq.Job) (any, error)
# v0.1.1 handler signature:    func(ctx context.Context, *echomq.Job) (any, error)
#
# This script is INTENTIONALLY non-mutating: it reports sites for human review
# rather than applying sed. Handler call sites can be structurally complex
# (closures, method receivers, function-typed locals), and auto-rewrite risk
# exceeds the manual-review cost. See MIGRATION.md §"Mechanical sed pattern"
# for the opt-in command reviewers may run themselves.
#
# Usage:
#   ./migrate-v0.1.0-to-v0.1.1.sh [--dry-run] [--root <path>]
#
# Flags:
#   --dry-run   Report candidate sites and exit non-zero if any found (default).
#               No destructive alternative exists — this script does not mutate.
#   --root PATH Directory to scan (default: current working directory).
#   --help      Show this message and exit.
#
# Exit codes:
#   0  No candidate v0.1.0 handler sites found (no-op migration; safe to upgrade).
#   1  Candidate sites found; reviewer must hand-edit each reported location.
#   2  Script invocation error (missing dependency, bad flag, unreadable root).
#
# Dependencies: grep (ripgrep used if available for speed), find, basename.

set -euo pipefail

ROOT="."
DRY_RUN=1

print_help() {
    sed -n '2,30p' "$0" | sed 's/^# //; s/^#//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --root)
            if [[ $# -lt 2 ]]; then
                echo "error: --root requires a path argument" >&2
                exit 2
            fi
            ROOT="$2"
            shift 2
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            echo "error: unknown flag '$1' (try --help)" >&2
            exit 2
            ;;
    esac
done

if [[ ! -d "$ROOT" ]]; then
    echo "error: root '$ROOT' is not a readable directory" >&2
    exit 2
fi

# Pattern 1: anonymous function handler without ctx parameter.
#   worker.Process(func(job *echomq.Job) (any, error) { ... })
#   worker.ProcessWithResults("x", func(j *echomq.Job) (interface{}, error) { ... })
PATTERN_ANON_HANDLER='func\s*\(\s*[a-zA-Z_][a-zA-Z0-9_]*\s+\*echomq\.Job\s*\)\s*\((any|interface\{\})\s*,\s*error\s*\)'

# Pattern 2: named function type declaration matching the v0.1.0 shape.
#   type JobProcessor func(*echomq.Job) (interface{}, error)
PATTERN_TYPE_DECL='^\s*type\s+\w+\s+func\s*\(\s*\*echomq\.Job\s*\)\s*\((any|interface\{\})\s*,\s*error\s*\)'

# Pattern 3: named function declaration that takes exactly one *echomq.Job (no ctx).
#   func processOrder(job *echomq.Job) (any, error) { ... }
PATTERN_NAMED_FUNC='^\s*func\s+\w+\s*\(\s*[a-zA-Z_][a-zA-Z0-9_]*\s+\*echomq\.Job\s*\)\s*\((any|interface\{\})\s*,\s*error\s*\)'

# Prefer ripgrep when available (faster; Go-aware via --type go).
if command -v rg >/dev/null 2>&1; then
    SEARCH_CMD=(rg --type go --line-number --column --color=never)
else
    SEARCH_CMD=(grep -rn --include='*.go')
fi

scan_pattern() {
    local label="$1"
    local pattern="$2"
    local hits
    if hits=$("${SEARCH_CMD[@]}" "$pattern" "$ROOT" 2>/dev/null); then
        if [[ -n "$hits" ]]; then
            printf '\n[candidate: %s]\n' "$label"
            printf '%s\n' "$hits"
            return 0
        fi
    fi
    return 1
}

printf 'echomq-go v0.1.0 -> v0.1.1 migration scanner\n'
printf 'root: %s\n' "$ROOT"
printf 'mode: %s\n' "$(if [[ $DRY_RUN -eq 1 ]]; then echo "dry-run (scan-only, non-mutating)"; else echo "unknown"; fi)"

FOUND=0

if scan_pattern 'anonymous handler (no ctx)' "$PATTERN_ANON_HANDLER"; then
    FOUND=1
fi
if scan_pattern 'named handler type declaration' "$PATTERN_TYPE_DECL"; then
    FOUND=1
fi
if scan_pattern 'named handler function' "$PATTERN_NAMED_FUNC"; then
    FOUND=1
fi

printf '\n'
if [[ $FOUND -eq 0 ]]; then
    printf 'no candidate v0.1.0 handler patterns found. safe to upgrade.\n'
    printf 'run `go get github.com/fiberfx/echomq-go@v0.1.1` and re-run `go build ./...`.\n'
    exit 0
fi

printf 'candidate sites reported above require manual edit per MIGRATION.md.\n'
printf 'next steps:\n'
printf '  1. review each reported site; confirm it is an echomq handler (false positives possible).\n'
printf '  2. add `ctx context.Context` as the first parameter; thread through caller-supplied ctx.\n'
printf '  3. run `go build ./...` to surface remaining compile errors.\n'
printf '  4. run `go vet -all ./...` to catch subtle mismatches.\n'
printf '  5. run integration tests against a real Redis to validate behavior.\n'
exit 1
