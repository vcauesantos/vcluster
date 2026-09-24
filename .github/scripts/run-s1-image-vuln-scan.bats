#!/usr/bin/env bats

setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github-output"
  export TARGET_IMAGE="ghcr.io/example/image@sha256:abc"
  export S1_CNS_CLI_BIN="$BATS_TEST_DIRNAME/testdata/fake-s1-cns-cli.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "exports severity counts and treats completed findings as advisory" {
  export FAKE_SCAN_RESULT=findings

  run "$BATS_TEST_DIRNAME/run-s1-image-vuln-scan.sh"

  [ "$status" -eq 0 ]
  grep -qx 'scan-completed=true' "$GITHUB_OUTPUT"
  grep -qx 'scanner-exit-code=1' "$GITHUB_OUTPUT"
  grep -qx 'critical-count=1' "$GITHUB_OUTPUT"
  grep -qx 'high-count=2' "$GITHUB_OUTPUT"
  grep -qx 'medium-count=1' "$GITHUB_OUTPUT"
  grep -qx 'low-count=3' "$GITHUB_OUTPUT"
  grep -qx 'total-count=7' "$GITHUB_OUTPUT"
}

@test "preserves scanner errors as failures with unavailable counts" {
  export FAKE_SCAN_RESULT=error

  run "$BATS_TEST_DIRNAME/run-s1-image-vuln-scan.sh"

  [ "$status" -eq 2 ]
  grep -qx 'scan-completed=false' "$GITHUB_OUTPUT"
  grep -qx 'scanner-exit-code=2' "$GITHUB_OUTPUT"
  grep -qx 'critical-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'high-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'medium-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'low-count=n/a' "$GITHUB_OUTPUT"
  grep -qx 'total-count=n/a' "$GITHUB_OUTPUT"
}
