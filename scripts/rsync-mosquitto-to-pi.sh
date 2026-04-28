#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/rsync-mosquitto-to-pi.sh --host <hostname-or-ip> [options]

Options:
  --host <host>              Raspberry Pi hostname or IP address
  --user <user>              SSH user name. Default: pi
  --remote-dir <path>        Remote broker stack directory.
                             Default: /mnt/nvme/mqtt
  --port <port>              SSH port. Default: 22
  --dry-run                  Show what would change without copying files
  -h, --help                 Show this help

Examples:
  ./scripts/rsync-mosquitto-to-pi.sh --host raspberrypi.local --dry-run
  ./scripts/rsync-mosquitto-to-pi.sh --host 192.168.1.44
  ./scripts/rsync-mosquitto-to-pi.sh --host 192.168.1.44 --user mqttadmin --remote-dir /srv/mosquitto
EOF
}

host=""
user="pi"
remote_dir="/mnt/nvme/mqtt"
port="22"
dry_run="false"

while (($# > 0)); do
  case "$1" in
    --host)
      host="${2:-}"
      shift 2
      ;;
    --user)
      user="${2:-}"
      shift 2
      ;;
    --remote-dir)
      remote_dir="${2:-}"
      shift 2
      ;;
    --port)
      port="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$host" ]]; then
  echo "--host is required" >&2
  usage >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
compose_file="${repo_root}/docker-compose.yml"
config_files=(
  "${repo_root}/mosquitto.conf"
  "${repo_root}/passwords"
  "${repo_root}/aclfile"
)
remote="${user}@${host}"

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required but not installed" >&2
  exit 1
fi

if [[ ! -f "$compose_file" ]]; then
  echo "Compose file not found: $compose_file" >&2
  exit 1
fi

for config_file in "${config_files[@]}"; do
  if [[ ! -f "$config_file" ]]; then
    echo "Config file not found: $config_file" >&2
    exit 1
  fi
done

rsync_args=(
  --archive
  --compress
  --delete
  --human-readable
  --itemize-changes
  --exclude=.DS_Store
  --rsh
  "ssh -p ${port}"
)

if [[ "$dry_run" == "true" ]]; then
  rsync_args+=(--dry-run)
fi

echo "Syncing broker files -> ${remote}:${remote_dir}/"
mkdir_cmd="mkdir -p '${remote_dir}'"
ssh -p "$port" "$remote" "$mkdir_cmd"
rsync "${rsync_args[@]}" "${compose_file}" "${remote}:${remote_dir}/docker-compose.yml"
for config_file in "${config_files[@]}"; do
  rsync "${rsync_args[@]}" "${config_file}" "${remote}:${remote_dir}/"
done
rsync "${rsync_args[@]}" "${repo_root}/docs/" "${remote}:${remote_dir}/docs/"
rsync "${rsync_args[@]}" "${repo_root}/scripts/" "${remote}:${remote_dir}/scripts/"

echo
echo "Sync complete."
echo "Remote stack path: ${remote_dir}"
echo "Files synced:"
echo "  - docker-compose.yml"
echo "  - mosquitto.conf"
echo "  - passwords"
echo "  - aclfile"
echo "  - docs/"
echo "  - scripts/"
echo "If you changed docker-compose.yml, mosquitto.conf, passwords, or aclfile, restart the broker on the Raspberry Pi."
