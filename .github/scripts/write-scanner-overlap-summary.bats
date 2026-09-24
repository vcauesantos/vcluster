#!/usr/bin/env bats

setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  export S1_IDS="CVE-1,CVE-2,CVE-3"
  export SNYK_IDS="CVE-2,CVE-3,CVE-4,CVE-6"
  export MEND_IDS="CVE-3,CVE-4,CVE-5"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "writes pairwise, three-way, and scanner-only identifier sets" {
  run "$BATS_TEST_DIRNAME/write-scanner-overlap-summary.sh"

  [ "$status" -eq 0 ]
  grep -Fq '| All three scanners | 1 | `CVE-3` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| SentinelOne ∩ Snyk | 2 | `CVE-2`, `CVE-3` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| SentinelOne ∩ Mend | 1 | `CVE-3` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| Snyk ∩ Mend | 2 | `CVE-3`, `CVE-4` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| SentinelOne only | 1 | `CVE-1` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| Snyk only | 1 | `CVE-6` |' "$GITHUB_STEP_SUMMARY"
  grep -Fq '| Mend only | 1 | `CVE-5` |' "$GITHUB_STEP_SUMMARY"
}
