#!/bin/sh

set -eu

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
: "${TARGET_IMAGE:?TARGET_IMAGE is required}"

s1_cns_cli_bin="${S1_CNS_CLI_BIN:-s1-cns-cli}"
scan_log="$(mktemp)"
trap 'rm -f "$scan_log"' EXIT HUP INT TERM

set +e
"$s1_cns_cli_bin" scan vuln --docker-image "$TARGET_IMAGE" >"$scan_log" 2>&1
scanner_exit_code=$?
set -e

cat "$scan_log"

if grep -q 'RESULT.*Scan completed' "$scan_log"; then
  {
    echo "scan-completed=true"
    echo "scanner-exit-code=$scanner_exit_code"
  } >> "$GITHUB_OUTPUT"

  awk -F '|' '
    NF >= 4 {
      severity=$3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", severity)
      severity=tolower(severity)
      if (severity == "critical" || severity == "high" || severity == "medium" || severity == "low") {
        counts[severity]++
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

if [ "$scanner_exit_code" -eq 0 ]; then
  exit 1
fi

exit "$scanner_exit_code"
