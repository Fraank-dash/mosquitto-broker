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
- [docs/secure-broker-howto.md](docs/secure-broker-howto.md)
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

## Runtime Model

This fork keeps the same secure broker startup pattern as the parent repo:

- the host config directory is mounted read-only
- the container copies `mosquitto.conf`, `passwords`, and `aclfile` into `/mosquitto/config`
- the copied files get restricted permissions before Mosquitto starts

That means host-side files are the source of truth, and broker auth changes require a broker restart.

## Notes

- the included `passwords` and `aclfile` are development/test assets carried over from the source repo
- this fork is broker-only; it does not include the subscriber, publisher, or TimescaleDB stack from `mqtt2postgres`
