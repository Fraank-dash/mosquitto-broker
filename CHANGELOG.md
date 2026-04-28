# Changelog

## 0.9.1-fork.1 - 2026-04-28

### Topic: Broker Operations
- Added helper scripts for hashing Mosquitto passwords, managing per-user ACL blocks, and syncing the broker stack to a Raspberry Pi host.
- Documented the broker auth update flow, Raspberry Pi sync flow, and local restart requirements in `docs/secure-broker-howto.md`.
- Added `docs/shelly-gen1-mqtt-onboarding.md` with a broker-local Shelly Gen1 onboarding guide.

### Topic: Broker Runtime
- Added optional Compose hostname and domain configuration through `MQTT_HOSTNAME` and `MQTT_ZONE`.
- Expanded the README with broker deployment, DNS, and Raspberry Pi sync guidance.
- Replaced the sample password and ACL entries with the current broker user set, including admin and subscriber accounts.

### Topic: Public/Private Workflow
- Reworked the public branch so the active broker files live at the repository root, allowing the repo to be mounted directly as a submodule-backed config directory.
- Removed tracked development password hashes from the public branch and replaced them with an empty `passwords` file plus a `passwords.example` template.
- Added documentation for running one local checkout against both a public `origin` remote and a private `private` remote with a dedicated `private/main` branch.

## 0.9.1-fork.0 - 2026-04-27

### Topic: Fork Bootstrap
- Created the standalone `mosquitto-broker` fork from the broker-specific assets in `mqtt2postgres`.
- Carried over the secure Mosquitto configuration, password file, and ACL file from the `mqtt2postgres` `0.9.1` baseline.
- Added a broker-only `docker-compose.yml` and broker-specific operational documentation.

### Topic: Fork Metadata
- Added a dedicated `README.md`.
- Added `FORKNOTE.md` documenting provenance and scope boundaries.
