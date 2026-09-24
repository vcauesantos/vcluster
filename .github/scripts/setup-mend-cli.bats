#!/usr/bin/env bats

setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"
  export RUNNER_TEMP="$TEST_TMPDIR/runner-temp"
  export GITHUB_PATH="$TEST_TMPDIR/github-path"
  mkdir -p "$RUNNER_TEMP" "$TEST_TMPDIR/source"
  printf '#!/bin/sh\necho fake mend\n' > "$TEST_TMPDIR/source/mend"
  sha256sum "$TEST_TMPDIR/source/mend" | awk '{print $1}' > "$TEST_TMPDIR/source/mend.sha256"
  export MEND_CLI_URL="file://$TEST_TMPDIR/source/mend"
  export MEND_CLI_SHA256
  MEND_CLI_SHA256="$(cat "$TEST_TMPDIR/source/mend.sha256")"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "installs only a Mend CLI binary matching the published checksum" {
  run "$BATS_TEST_DIRNAME/setup-mend-cli.sh"

  [ "$status" -eq 0 ]
  [ -x "$RUNNER_TEMP/mend-cli/mend" ]
  grep -qx "$RUNNER_TEMP/mend-cli" "$GITHUB_PATH"
}

@test "rejects a Mend CLI binary that does not match the pinned checksum" {
  export MEND_CLI_SHA256=0000000000000000000000000000000000000000000000000000000000000000

  run "$BATS_TEST_DIRNAME/setup-mend-cli.sh"

  [ "$status" -ne 0 ]
  [ ! -x "$RUNNER_TEMP/mend-cli/mend" ]
}
