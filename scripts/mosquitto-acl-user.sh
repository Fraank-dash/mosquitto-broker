#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  ./scripts/mosquitto-acl-user.sh get <username> [target-file]
  ./scripts/mosquitto-acl-user.sh remove <username> [target-file]
  ./scripts/mosquitto-acl-user.sh set <username> <topic-line> [<topic-line> ...] [--target-file <path>]

Commands:
  get       Print the ACL block for one user
  remove    Remove the ACL block for one user from the target file
  set       Replace the ACL block for one user, or append it if missing

Topic lines for set must be complete ACL lines, for example:
  "topic write shellies/washing-plug/#"
  "topic read shellies/washing-plug/relay/0/command"

Defaults:
  target file: ./mosquitto/aclfile

Examples:
  ./scripts/mosquitto-acl-user.sh get washing-plug
  ./scripts/mosquitto-acl-user.sh remove washing-plug
  ./scripts/mosquitto-acl-user.sh set washing-plug "topic write shellies/washing-plug/#" "topic read shellies/washing-plug/relay/0/command"
  ./scripts/mosquitto-acl-user.sh set washing-plug "topic write #" "topic read #" --target-file ./mosquitto/aclfile
EOF
}

if [ "$#" -lt 2 ]; then
  usage >&2
  exit 1
fi

command_name="$1"
username="$2"
shift 2

if [ -z "$username" ]; then
  echo "Username is required" >&2
  usage >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "${script_dir}/.." && pwd)
default_target_file="${repo_root}/mosquitto/aclfile"
target_file="$default_target_file"

get_block() {
  awk -v username="$1" '
    /^user / {
      if (printing) {
        exit
      }
      printing = ($0 == "user " username)
    }
    printing {
      print
    }
  ' "$2"
}

rewrite_file() {
  mode="$1"
  user="$2"
  file="$3"
  replacement_payload="$4"
  tmp_file="$(mktemp)"

  awk -v mode="$mode" -v username="$user" -v replacement="$replacement_payload" '
    function emit_block(block_user,   i, n, lines) {
      if (block_user == "") {
        return
      }

      if (block_user == username) {
        found = 1
        if (mode == "set") {
          print "user " username
          n = split(replacement, lines, "\034")
          for (i = 1; i <= n; i++) {
            if (lines[i] != "") {
              print lines[i]
            }
          }
          print ""
        }
      } else {
        for (i = 1; i <= block_count; i++) {
          print block_lines[i]
        }
        print ""
      }
    }

    /^user / {
      emit_block(current_user)
      delete block_lines
      block_count = 0
      current_user = substr($0, 6)
    }

    {
      if (current_user == "") {
        prelude[++prelude_count] = $0
      } else {
        block_lines[++block_count] = $0
      }
    }

    END {
      if (current_user == "") {
        for (i = 1; i <= prelude_count; i++) {
          print prelude[i]
        }
      } else {
        for (i = 1; i <= prelude_count; i++) {
          print prelude[i]
        }
        if (prelude_count > 0) {
          print ""
        }
        emit_block(current_user)
      }

      if (mode == "set" && !found) {
        print "user " username
        n = split(replacement, lines, "\034")
        for (i = 1; i <= n; i++) {
          if (lines[i] != "") {
            print lines[i]
          }
        }
        print ""
      }
    }
  ' "$file" > "$tmp_file"

  mv "$tmp_file" "$file"
}

case "$command_name" in
  get|remove)
    if [ "$#" -gt 1 ]; then
      usage >&2
      exit 1
    fi
    if [ "$#" -eq 1 ]; then
      target_file="$1"
    fi
    ;;
  set)
    replacement_payload=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --target-file)
          if [ "$#" -lt 2 ]; then
            echo "--target-file requires a path" >&2
            exit 1
          fi
          target_file="$2"
          shift 2
          ;;
        *)
          replacement_payload="${replacement_payload}$1$(printf '\034')"
          shift
          ;;
      esac
    done

    if [ -z "$replacement_payload" ]; then
      echo "set requires at least one topic line" >&2
      usage >&2
      exit 1
    fi
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [ ! -f "$target_file" ]; then
  if [ "$command_name" = "get" ]; then
    echo "ACL file not found: $target_file" >&2
    exit 1
  fi
  touch "$target_file"
fi

case "$command_name" in
  get)
    acl_block="$(get_block "$username" "$target_file")"
    if [ -z "$acl_block" ]; then
      echo "No ACL block found for ${username} in ${target_file}" >&2
      exit 1
    fi
    printf '%s\n' "$acl_block"
    ;;
  remove)
    rewrite_file "remove" "$username" "$target_file" ""
    printf 'Removed %s from %s\n' "$username" "$target_file"
    ;;
  set)
    rewrite_file "set" "$username" "$target_file" "$replacement_payload"
    printf 'Set %s in %s\n' "$username" "$target_file"
    ;;
esac
