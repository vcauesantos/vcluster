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
      id=$2
      severity=$3
      package=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", severity)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", package)
      severity=tolower(severity)
      if (severity == "critical" || severity == "high" || severity == "medium" || severity == "low") {
        counts[severity]++
        ids[id]=1
        if (package == "stdlib" || package ~ /\//) {
          go_findings++
        } else {
          os_findings++
          os_ids[id]=1
        }
      }
    }
    END {
      total=counts["critical"] + counts["high"] + counts["medium"] + counts["low"]
      for (id in ids) unique_ids++
      for (id in os_ids) unique_os_ids++
      printf "critical-count=%d\n", counts["critical"]
      printf "high-count=%d\n", counts["high"]
      printf "medium-count=%d\n", counts["medium"]
      printf "low-count=%d\n", counts["low"]
      printf "total-count=%d\n", total
      printf "unique-id-count=%d\n", unique_ids
      printf "go-finding-count=%d\n", go_findings
      printf "os-finding-count=%d\n", os_findings
      printf "os-unique-id-count=%d\n", unique_os_ids
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
  echo "unique-id-count=n/a"
  echo "go-finding-count=n/a"
  echo "os-finding-count=n/a"
  echo "os-unique-id-count=n/a"
} >> "$GITHUB_OUTPUT"

if [ "$scanner_exit_code" -eq 0 ]; then
  exit 1
fi

exit "$scanner_exit_code"
