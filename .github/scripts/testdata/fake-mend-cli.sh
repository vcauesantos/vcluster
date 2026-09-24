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
report_format=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--filename" ]; then
    report_file="$argument"
  fi
  if [ "$previous" = "--format" ]; then
    report_format="$argument"
  fi
  previous="$argument"
done

case "${FAKE_MEND_RESULT:-findings}" in
  findings)
    if [ -n "$report_file" ]; then
      printf '{}\n' > "$report_file"
      exit 0
    fi
    if [ "$report_format" = "json" ]; then
      printf '{}\n'
      exit 0
    fi
    cat <<'EOF'
Detected 5 Vulnerabilities (CRITICAL: 1, HIGH: 2, MEDIUM: 1, LOW: 0, UNKNOWN: 1)
| Library             | Severity | Installed Version | Fixed Version | Details          |
| stdlib              | Critical | 1.0               | 1.1           | CVE-0001         |
| github.com/acme/a   | High     | 1.0               | 1.1           | CVE-0002         |
| zlib                | High     | 1.0               | 1.1           | CVE-0003         |
| busybox             | Medium   | 1.0               | 1.1           | CVE-0004         |
| github.com/acme/b   |          | 1.0               | 1.1           | GHSA-0005        |
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
