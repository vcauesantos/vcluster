#!/usr/bin/env bats

setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github-output"
  export RUNNER_TEMP="$TEST_TMPDIR/runner-temp"
  export TARGET_IMAGE="ghcr.io/example/image@sha256:abc"
  export MEND_CLI_BIN="$BATS_TEST_DIRNAME/testdata/fake-mend-cli.sh"
  mkdir -p "$RUNNER_TEMP"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "exports Mend terminal-table counts after a successful scan" {
  export FAKE_MEND_RESULT=findings

  run "$BATS_TEST_DIRNAME/run-mend-image-vuln-scan.sh"

  [ "$status" -eq 0 ]
  grep -qx 'scan-completed=true' "$GITHUB_OUTPUT"
  grep -qx 'scanner-exit-code=0' "$GITHUB_OUTPUT"
  grep -qx 'critical-count=1' "$GITHUB_OUTPUT"
  grep -qx 'high-count=2' "$GITHUB_OUTPUT"
  grep -qx 'medium-count=1' "$GITHUB_OUTPUT"
  grep -qx 'low-count=0' "$GITHUB_OUTPUT"
  grep -qx 'unknown-count=1' "$GITHUB_OUTPUT"
  grep -qx 'total-count=5' "$GITHUB_OUTPUT"
}

@test "preserves Mend scanner errors without publishing partial counts" {
  export FAKE_MEND_RESULT=error

  run "$BATS_TEST_DIRNAME/run-mend-image-vuln-scan.sh"

  [ "$status" -eq 2 ]
  grep -qx 'scan-completed=false' "$GITHUB_OUTPUT"
  grep -qx 'scanner-exit-code=2' "$GITHUB_OUTPUT"
  grep -qx 'critical-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'high-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'medium-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'low-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'unknown-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'total-count=n/a' "$GITHUB_OUTPUT"
}
