#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  ./scripts/mosquitto-hash-password.sh <username> <plain-password> [target-file]

Print one Mosquitto password-file line, or write it into a target file:
  <username>:<hash>

Examples:
  ./scripts/mosquitto-hash-password.sh washer-plug washer-plug-secret
  ./scripts/mosquitto-hash-password.sh washer-plug washer-plug-secret ./mosquitto/passwords
EOF
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage >&2
  exit 1
fi

username="$1"
plain_password="$2"
target_file="${3:-}"

if [ -z "$username" ] || [ -z "$plain_password" ]; then
  echo "Username and plain password are required" >&2
  usage >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but not installed" >&2
  exit 1
fi

docker_context="${DOCKER_CONTEXT:-default}"

hash_line="$(
  docker --context "$docker_context" run --rm eclipse-mosquitto:2 \
    sh -c "mosquitto_passwd -c -b /tmp/passwords \"$username\" \"$plain_password\" >/dev/null && cat /tmp/passwords"
)"

case "$hash_line" in
  "$username":*)
    ;;
  *)
    echo "Failed to generate a valid Mosquitto password line for ${username}" >&2
    exit 1
    ;;
esac

if [ -z "$target_file" ]; then
  printf '%s\n' "$hash_line"
  exit 0
fi

touch "$target_file"

if grep -q "^${username}:" "$target_file"; then
  tmp_file="$(mktemp)"
  awk -v username="$username" -v replacement="$hash_line" '
    BEGIN {
      replaced = 0
    }
    $0 ~ ("^" username ":") {
      print replacement
      replaced = 1
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        print replacement
      }
    }
  ' "$target_file" > "$tmp_file"
  mv "$tmp_file" "$target_file"
  printf 'Updated %s in %s\n' "$username" "$target_file"
else
  printf '%s\n' "$hash_line" >> "$target_file"
  printf 'Appended %s to %s\n' "$username" "$target_file"
fi
