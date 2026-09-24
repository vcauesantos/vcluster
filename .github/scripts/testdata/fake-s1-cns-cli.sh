#!/bin/sh

if [ "$1 $2 $3" != "scan vuln --docker-image" ]; then
  echo "unexpected arguments: $*" >&2
  exit 64
fi

case "${FAKE_SCAN_RESULT:-findings}" in
  findings)
    cat <<'EOF'
+----------+----------+---------+
| Id       | Severity | Package |
+----------+----------+---------+
| CVE-0001 | Critical | one     |
| CVE-0002 | High     | two     |
| CVE-0003 | High     | three   |
| CVE-0004 | Medium   | four    |
| CVE-0005 | Low      | five    |
| CVE-0006 | Low      | six     |
| CVE-0007 | Low      | seven   |
+----------+----------+---------+
RESULT Scan completed. Found 7 issues.
EOF
    exit 1
    ;;
  error)
    echo "ERROR vulnerability database unavailable"
    exit 2
    ;;
  *)
    echo "unknown fake result" >&2
    exit 64
    ;;
esac
