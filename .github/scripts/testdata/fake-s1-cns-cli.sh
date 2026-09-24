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
| CVE-0001 | Critical | stdlib             |
| CVE-0002 | High     | github.com/acme/a  |
| CVE-0003 | High     | zlib               |
| CVE-0004 | Medium   | busybox            |
| CVE-0005 | Low      | busybox            |
| CVE-0005 | Low      | ssl_client         |
| CVE-0006 | Low      | golang.org/x/mod   |
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
