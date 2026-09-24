#!/bin/sh

set -eu

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
: "${TARGET_IMAGE:?TARGET_IMAGE is required}"

mend_cli_bin="${MEND_CLI_BIN:-mend}"
scan_log="$(mktemp)"
trap 'rm -f "$scan_log"' EXIT HUP INT TERM

set +e
"$mend_cli_bin" image "$TARGET_IMAGE" \
  --non-interactive \
  --show vuln \
  --skip-security-checks secret >"$scan_log" 2>&1
scanner_exit_code=$?
set -e

cat "$scan_log"

if [ "$scanner_exit_code" -eq 0 ]; then
  {
    echo "scan-completed=true"
    echo "scanner-exit-code=$scanner_exit_code"
  } >> "$GITHUB_OUTPUT"

  awk -F '|' '
    {
      for (field = 1; field <= NF; field++) {
        value=$field
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        value=tolower(value)
        if (value == "critical" || value == "high" || value == "medium" || value == "low") {
          counts[value]++
          break
        }
      }
    }
    END {
      total=counts["critical"] + counts["high"] + counts["medium"] + counts["low"]
      printf "critical-count=%d\n", counts["critical"]
      printf "high-count=%d\n", counts["high"]
      printf "medium-count=%d\n", counts["medium"]
      printf "low-count=%d\n", counts["low"]
      printf "total-count=%d\n", total
    }
  ' "$scan_log" >> "$GITHUB_OUTPUT"

  exit 0
fi

{
  echo "scan-completed=false"
  echo "scanner-exit-code=$scanner_exit_code"
  echo "critical-count=n/a"
  echo "high-count=n/a"
  echo "medium-count=n/a"
  echo "low-count=n/a"
  echo "total-count=n/a"
} >> "$GITHUB_OUTPUT"

exit "$scanner_exit_code"
