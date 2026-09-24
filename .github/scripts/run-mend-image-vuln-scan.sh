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
      summary=tolower($0)
      if (summary ~ /^detected [0-9]+ vulnerabilities /) {
        gsub(/[(),:]/, " ", summary)
        word_count=split(summary, words, /[[:space:]]+/)
        for (word = 1; word <= word_count; word++) {
          if (words[word] == "detected") {
            summary_total=words[word + 1]
          } else if (words[word] == "critical" || words[word] == "high" ||
                     words[word] == "medium" || words[word] == "low" ||
                     words[word] == "unknown") {
            summary_counts[words[word]]=words[word + 1]
          }
        }
        found_summary=1
      }

      for (field = 1; field <= NF; field++) {
        value=$field
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        value=tolower(value)
        if (value == "critical" || value == "high" || value == "medium" || value == "low") {
          table_counts[value]++
          break
        }
      }
    }
    END {
      if (found_summary) {
        total=summary_total
        for (severity in summary_counts) {
          counts[severity]=summary_counts[severity]
        }
      } else {
        total=table_counts["critical"] + table_counts["high"] + table_counts["medium"] + table_counts["low"]
        for (severity in table_counts) {
          counts[severity]=table_counts[severity]
        }
      }
      printf "critical-count=%d\n", counts["critical"]
      printf "high-count=%d\n", counts["high"]
      printf "medium-count=%d\n", counts["medium"]
      printf "low-count=%d\n", counts["low"]
      printf "unknown-count=%d\n", counts["unknown"]
      printf "total-count=%d\n", total
    }
  ' "$scan_log" >> "$GITHUB_OUTPUT"

  normalized_ids="$(awk -F '|' '
    {
      for (field = 1; field <= NF; field++) {
        value=$field
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value ~ /^(CVE|GHSA|SNYK)-/) {
          print toupper(value)
          break
        }
      }
    }
  ' "$scan_log" | LC_ALL=C sort -u | paste -sd, -)"
  unique_id_count="$(printf '%s\n' "$normalized_ids" | awk -F, '{ print ($0 == "" ? 0 : NF) }')"
  {
    echo "unique-id-count=$unique_id_count"
    echo "normalized-ids=$normalized_ids"
  } >> "$GITHUB_OUTPUT"

  exit 0
fi

{
  echo "scan-completed=false"
  echo "scanner-exit-code=$scanner_exit_code"
  echo "critical-count=n/a"
  echo "high-count=n/a"
  echo "medium-count=n/a"
  echo "low-count=n/a"
  echo "unknown-count=n/a"
  echo "total-count=n/a"
  echo "unique-id-count=n/a"
  echo "normalized-ids="
} >> "$GITHUB_OUTPUT"

exit "$scanner_exit_code"
