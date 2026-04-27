# Fork Note

This repository was fork-scaffolded from the Mosquitto-specific local stack assets in `mqtt2postgres`.

## Source Provenance

- source repository: `mqtt2postgres`
- source baseline version: `0.9.1`
- source baseline date: `2026-04-26`
- fork scaffold date: `2026-04-27`

## Source Scope

The fork started from the broker-facing portion of the parent repo, primarily:

- `examples/local-stack/docker-compose.yml` broker service
- `examples/local-stack/mosquitto/mosquitto.conf`
- `examples/local-stack/mosquitto/passwords`
- `examples/local-stack/mosquitto/aclfile`
- `docs/secure-broker-howto.md`

## Intent

The intent of this fork is to split the Mosquitto broker setup into a separate repository with its own:

- `README.md`
- `CHANGELOG.md`
- broker-only Compose runtime
- broker-only operational docs

## Non-Goals Of This Fork

This fork does not currently carry over:

- the synthetic publisher runtime
- the subscriber/ingestor runtime
- the TimescaleDB bootstrap
- the SQL ingest pipeline
- the full `mqtt2postgres` documentation set

## First Fork Version

The initial fork changelog entry is `0.9.1-fork.0` to make the parent baseline explicit.
