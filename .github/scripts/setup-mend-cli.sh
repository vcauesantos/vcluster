#!/bin/sh

set -eu

: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"

mend_cli_url="${MEND_CLI_URL:-https://downloads.mend.io/cli/linux_amd64/mend}"
mend_cli_sha256="${MEND_CLI_SHA256:-cac6db6c83bb367d22ae7f0c4c443c5a39af8e59699d6c36f0897122eaf7bd8b}"
install_dir="$RUNNER_TEMP/mend-cli"
download_file="$install_dir/mend.download"
installed_file="$install_dir/mend"

mkdir -p "$install_dir"
trap 'rm -f "$download_file"' EXIT HUP INT TERM

curl --fail --silent --show-error --location "$mend_cli_url" --output "$download_file"

case "$mend_cli_sha256" in
  ''|*[!0-9A-Fa-f]*)
    echo "Pinned Mend CLI checksum is invalid" >&2
    exit 1
    ;;
esac

if [ "${#mend_cli_sha256}" -ne 64 ]; then
  echo "Pinned Mend CLI checksum must be a SHA-256 digest" >&2
  exit 1
fi

printf '%s  %s\n' "$mend_cli_sha256" "$download_file" | sha256sum -c - >/dev/null
mv "$download_file" "$installed_file"
chmod 0755 "$installed_file"
printf '%s\n' "$install_dir" >> "$GITHUB_PATH"
