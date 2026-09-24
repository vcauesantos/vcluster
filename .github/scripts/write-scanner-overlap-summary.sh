#!/usr/bin/env bash

set -euo pipefail

: "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"

comparison_dir="$(mktemp -d)"
trap 'rm -rf "$comparison_dir"' EXIT HUP INT TERM

normalize_csv() {
  printf '%s\n' "$1" |
    tr ',' '\n' |
    awk '
      {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        value=toupper($0)
        if (value ~ /^(CVE|GHSA|SNYK)-/) print value
      }
    ' |
    LC_ALL=C sort -u
}

normalize_csv "${S1_IDS:-}" > "$comparison_dir/s1"
normalize_csv "${SNYK_IDS:-}" > "$comparison_dir/snyk"
normalize_csv "${MEND_IDS:-}" > "$comparison_dir/mend"

comm -12 "$comparison_dir/s1" "$comparison_dir/snyk" > "$comparison_dir/s1-snyk"
comm -12 "$comparison_dir/s1" "$comparison_dir/mend" > "$comparison_dir/s1-mend"
comm -12 "$comparison_dir/snyk" "$comparison_dir/mend" > "$comparison_dir/snyk-mend"
comm -12 "$comparison_dir/s1-snyk" "$comparison_dir/mend" > "$comparison_dir/all"

LC_ALL=C sort -u "$comparison_dir/snyk" "$comparison_dir/mend" > "$comparison_dir/not-s1"
LC_ALL=C sort -u "$comparison_dir/s1" "$comparison_dir/mend" > "$comparison_dir/not-snyk"
LC_ALL=C sort -u "$comparison_dir/s1" "$comparison_dir/snyk" > "$comparison_dir/not-mend"
comm -23 "$comparison_dir/s1" "$comparison_dir/not-s1" > "$comparison_dir/only-s1"
comm -23 "$comparison_dir/snyk" "$comparison_dir/not-snyk" > "$comparison_dir/only-snyk"
comm -23 "$comparison_dir/mend" "$comparison_dir/not-mend" > "$comparison_dir/only-mend"

format_ids() {
  awk '
    BEGIN { separator="" }
    { printf "%s`%s`", separator, $0; separator=", " }
    END { if (NR == 0) printf "—" }
  ' "$1"
}

write_row() {
  local label="$1" file="$2" count identifiers
  count="$(wc -l < "$file" | tr -d '[:space:]')"
  identifiers="$(format_ids "$file")"
  printf '| %s | %s | %s |\n' "$label" "$count" "$identifiers"
}

{
  echo
  echo "## Normalized vulnerability ID overlap"
  echo
  echo "This comparison uses case-normalized CVE/GHSA identifiers. A Snyk rule ID is used only when its SARIF finding exposes no standard alias."
  echo
  echo "| Set | Count | Identifiers |"
  echo "|-----|------:|-------------|"
  write_row "All three scanners" "$comparison_dir/all"
  write_row "SentinelOne ∩ Snyk" "$comparison_dir/s1-snyk"
  write_row "SentinelOne ∩ Mend" "$comparison_dir/s1-mend"
  write_row "Snyk ∩ Mend" "$comparison_dir/snyk-mend"
  write_row "SentinelOne only" "$comparison_dir/only-s1"
  write_row "Snyk only" "$comparison_dir/only-snyk"
  write_row "Mend only" "$comparison_dir/only-mend"
} >> "$GITHUB_STEP_SUMMARY"
