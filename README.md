# mosquitto-broker

Standalone fork of the local Mosquitto broker slice from `mqtt2postgres`.

This repo is intended to own only the broker-facing runtime assets:

- Mosquitto configuration
- password file
- ACL file
- broker-only Docker Compose setup
- broker-specific operational docs

## Fork Baseline

- forked from `mqtt2postgres`
- source baseline version: `0.9.1`
- fork date: `2026-04-27`

The detailed fork provenance is recorded in [FORKNOTE.md](FORKNOTE.md).

## Contents

- [docker-compose.yml](docker-compose.yml)
- [mosquitto/mosquitto.conf](mosquitto/mosquitto.conf)
- [mosquitto/passwords](mosquitto/passwords)
- [mosquitto/aclfile](mosquitto/aclfile)
- [scripts/rsync-mosquitto-to-pi.sh](scripts/rsync-mosquitto-to-pi.sh)
- [scripts/mosquitto-hash-password.sh](scripts/mosquitto-hash-password.sh)
- [scripts/mosquitto-acl-user.sh](scripts/mosquitto-acl-user.sh)
- [docs/secure-broker-howto.md](docs/secure-broker-howto.md)
- [docs/shelly-gen1-mqtt-onboarding.md](docs/shelly-gen1-mqtt-onboarding.md)
- [CHANGELOG.md](CHANGELOG.md)

## Quick Start

Start the broker:

```bash
docker compose up -d
```

Follow broker logs:

```bash
docker compose logs -f mqtt-broker
```

Add a Shelly Gen1 device:

See [docs/shelly-gen1-mqtt-onboarding.md](docs/shelly-gen1-mqtt-onboarding.md) for a broker-local onboarding guide and a worked `Shelly Plug / PlugS` example.

Stop the broker:

```bash
docker compose down
```

## Host Config Path

By default this fork mounts its own repo-local `./mosquitto` directory into the container.

If you prefer a stable host path such as `/mnt/nvme/mqtt/mosquitto`, override the mount path with:

```bash
MOSQUITTO_HOST_CONFIG_DIR=/mnt/nvme/mqtt/mosquitto docker compose up -d
```

If you want clients to reach the broker as `mqtt.<zone>`, set:

```bash
MQTT_HOSTNAME=mqtt
MQTT_ZONE=example.lan
```

Then create a Technitium DNS `A` record for `mqtt.example.lan` that points to the Raspberry Pi host IP running this stack.

To push the local broker stack to a Raspberry Pi, use:

```bash
./scripts/rsync-mosquitto-to-pi.sh --host raspberrypi.local --dry-run
./scripts/rsync-mosquitto-to-pi.sh --host raspberrypi.local
```

This syncs:

- `docker-compose.yml`
- `mosquitto/`

into the remote stack directory, which defaults to `/mnt/nvme/mqtt`.

## Runtime Model

This fork keeps the same secure broker startup pattern as the parent repo:

- the host config directory is mounted read-only
- the container copies `mosquitto.conf`, `passwords`, and `aclfile` into `/mosquitto/config`
- the copied files get restricted permissions before Mosquitto starts

That means host-side files are the source of truth, and broker auth changes require a broker restart.

## Notes

- the included `passwords` and `aclfile` are development/test assets carried over from the source repo
- this fork is broker-only; it does not include the subscriber, publisher, or TimescaleDB stack from `mqtt2postgres`
