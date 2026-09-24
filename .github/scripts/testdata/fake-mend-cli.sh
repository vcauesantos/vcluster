#!/bin/sh

if [ "$1" != "image" ] || [ "$2" != "${TARGET_IMAGE:?}" ]; then
  echo "unexpected image arguments: $*" >&2
  exit 64
fi

for argument in "$@"; do
  if [ "$argument" = "--scope" ]; then
    echo "unexpected explicit Mend scope" >&2
    exit 64
  fi
done

report_file=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--filename" ]; then
    report_file="$argument"
  fi
  previous="$argument"
done

case "${FAKE_MEND_RESULT:-findings}" in
  findings)
    : "${report_file:?--filename is required}"
    printf '{}\n' > "$report_file"
    cat <<'EOF'
| Library             | Severity | Installed Version | Fixed Version | Details          |
| stdlib              | Critical | 1.0               | 1.1           | CVE-0001         |
| github.com/acme/a   | High     | 1.0               | 1.1           | CVE-0002         |
| zlib                | High     | 1.0               | 1.1           | CVE-0003         |
| busybox             | Medium   | 1.0               | 1.1           | CVE-0004         |
Scan completed
EOF
    exit 0
    ;;
  error)
    echo "ERROR Mend service unavailable"
    exit 2
    ;;
  *)
    echo "unknown fake result" >&2
    exit 64
    ;;
esac
