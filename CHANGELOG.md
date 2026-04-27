# Changelog

## 0.9.1-fork.0 - 2026-04-27

### Topic: Fork Bootstrap
- Created the standalone `mosquitto-broker` fork from the broker-specific assets in `mqtt2postgres`.
- Carried over the secure Mosquitto configuration, password file, and ACL file from the `mqtt2postgres` `0.9.1` baseline.
- Added a broker-only `docker-compose.yml` and broker-specific operational documentation.

### Topic: Fork Metadata
- Added a dedicated `README.md`.
- Added `FORKNOTE.md` documenting provenance and scope boundaries.
