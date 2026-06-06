#!/usr/bin/env bash
# check-lua-drift.sh — Detect drift of embedded Lua script bodies from the
# BullMQ upstream pin.
#
# EchoMQ Go embeds BullMQ Lua scripts as Go raw-string constants in
# pkg/echomq/scripts/scripts.go. The D-5 invariant (spec.yaml + state.yaml)
# requires every embedded script body to be byte-identical to the upstream
# body at the pinned commit. This script enforces that invariant by SHA256-
# hashing each declared constant and comparing against the pin manifest at
# scripts/lua-pins.txt.
#
# Exit codes:
#   0  — all hashes match the manifest; no drift.
#   1  — internal error (missing file, malformed manifest, tool not found).
#   2  — drift detected; diff output printed to stderr.
#
# Usage:
#   scripts/check-lua-drift.sh           # run drift check
#   scripts/check-lua-drift.sh --help    # this help text
#
# Requires: bash >= 3.2, shasum (or sha256sum), awk, sed, diff. Portable on
# macOS default bash 3.2 and GNU bash >= 4.
#
# Re-pinning ceremony (when upgrading BullMQ pin):
#   1. Update commit SHA in CLAUDE.md §Protocol Version Compatibility and
#      dev/mcp/features/FTR-009-echomq-go-parity/state.yaml.
#   2. Regenerate scripts/lua-pins.txt from the new Go source.
#   3. Log a new D-n decision; run R-13 + R-14 compat suites.

set -o errexit
set -o pipefail
set -o nounset

# --help dispatch — exit 0 before any further setup so the help text is
# available even if the surrounding repo is not in a valid state.
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    sed -n '2,29p' "$0" | sed -e 's/^# \{0,1\}//'
    exit 0
fi

# Resolve paths relative to the location of this script so the target paths
# are correct whether invoked from the repo root or from scripts/.
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${script_dir}/.." && pwd)
scripts_go="${repo_root}/pkg/echomq/scripts/scripts.go"
pins_file="${script_dir}/lua-pins.txt"

if [ ! -f "${scripts_go}" ]; then
    echo "check-lua-drift: missing source file: ${scripts_go}" >&2
    exit 1
fi
if [ ! -f "${pins_file}" ]; then
    echo "check-lua-drift: missing pin manifest: ${pins_file}" >&2
    exit 1
fi

# Pick a SHA256 tool — macOS ships shasum, Linux typically sha256sum. Both
# are commonly installed on CI runners (ubuntu-latest, macos-latest).
if command -v shasum >/dev/null 2>&1; then
    sha256_cmd="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    sha256_cmd="sha256sum"
else
    echo "check-lua-drift: neither shasum nor sha256sum found in PATH" >&2
    exit 1
fi

# Extract a single Go raw-string constant body from scripts.go into a file.
# Handles the Go alias form `Name = OtherName` by following the alias target.
# Writes the raw bytes (INCLUDING the trailing newline that Go raw-strings
# preserve before their closing backtick) to the target path so that SHA256
# over the file matches the Go-computed SHA256 over the string value.
#
# Arguments: $1 = constant name (e.g. MoveToActive); $2 = output file path
# Exit:      0 on success; 1 on malformed source or missing constant
extract_constant_body() {
    local name="$1"
    local out="$2"
    local src="${scripts_go}"

    # Alias form: `Name = OtherName` (no backtick on declaration line).
    local alias_target
    alias_target=$(awk -v n="${name}" '
        $0 ~ "^[[:space:]]*" n "[[:space:]]*=[[:space:]]*[A-Za-z]+[[:space:]]*$" {
            for (i = 1; i <= NF; i++) {
                if ($i == "=") { print $(i + 1); exit }
            }
        }
    ' "${src}")

    if [ -n "${alias_target}" ]; then
        extract_constant_body "${alias_target}" "${out}"
        return $?
    fi

    # Standard form: `Name = \`...body...\``. awk writes each body line with
    # its trailing newline intact; the final `print` adds a newline after the
    # last content line, which matches the trailing \n Go preserves before
    # the closing backtick (verified against Go-dumped bytes).
    awk -v n="${name}" '
        BEGIN { capturing = 0 }
        capturing == 0 && $0 ~ "^[[:space:]]*" n "[[:space:]]*=[[:space:]]*`" {
            sub(/^[^`]*`/, "", $0)
            capturing = 1
            if ($0 ~ /`[[:space:]]*$/) {
                sub(/`[[:space:]]*$/, "", $0)
                print $0
                exit
            }
            print $0
            next
        }
        capturing == 1 {
            if ($0 ~ /^`$/) { exit }
            print $0
        }
    ' "${src}" > "${out}"

    if [ ! -s "${out}" ]; then
        return 1
    fi
    return 0
}

# Walk the pin manifest, hash each named constant, compare. Accumulates
# drift rows into a temp file for diff-style output.
tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

expected_file="${tmp_dir}/expected.txt"
actual_file="${tmp_dir}/actual.txt"

# Parse manifest: skip blanks + comments, keep `<sha>  <name>` rows.
grep -v '^[[:space:]]*#' "${pins_file}" | grep -v '^[[:space:]]*$' > "${expected_file}"

while IFS= read -r row; do
    expected_sha=$(echo "${row}" | awk '{print $1}')
    const_name=$(echo "${row}" | awk '{print $2}')

    if [ -z "${expected_sha}" ] || [ -z "${const_name}" ]; then
        echo "check-lua-drift: malformed manifest row: ${row}" >&2
        exit 1
    fi

    body_file="${tmp_dir}/${const_name}.body"
    if ! extract_constant_body "${const_name}" "${body_file}"; then
        echo "check-lua-drift: could not extract constant body: ${const_name}" >&2
        exit 1
    fi

    # Hash the file directly — shell command substitution strips trailing
    # newlines, so reading through a variable would corrupt the hash of
    # scripts whose Go raw-string bodies end in \n (all of them do).
    actual_sha=$(${sha256_cmd} "${body_file}" | awk '{print $1}')

    printf '%s  %s\n' "${actual_sha}" "${const_name}" >> "${actual_file}"
done < "${expected_file}"

# Compare; any difference → drift. Use `cmp -s` for exit-code hygiene and
# `diff -u` for the human-readable report.
if cmp -s "${expected_file}" "${actual_file}"; then
    echo "check-lua-drift: OK — all 9 scripts match pin ${pins_file}"
    exit 0
fi

{
    echo "check-lua-drift: DRIFT DETECTED"
    echo ""
    echo "Expected (from scripts/lua-pins.txt):"
    cat "${expected_file}"
    echo ""
    echo "Actual (recomputed from pkg/echomq/scripts/scripts.go):"
    cat "${actual_file}"
    echo ""
    echo "Unified diff:"
    diff -u "${expected_file}" "${actual_file}" || true
    echo ""
    echo "Remediation:"
    echo "  1. If scripts.go was legitimately updated to a new BullMQ pin, follow"
    echo "     the re-pinning ceremony in scripts/check-lua-drift.sh header + D-5."
    echo "  2. If scripts.go changed accidentally, revert with: git checkout --"
    echo "     pkg/echomq/scripts/scripts.go"
} >&2

exit 2
