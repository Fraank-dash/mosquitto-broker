# Secure Broker How-To

This is the standalone broker-only copy of the secure Mosquitto operational guide.

It focuses on the broker runtime, password file management, ACL management, and the safe restart flow for a read-only mounted config source.

## Current Layout

The fork is driven by these files:

- `docker-compose.yml`
- `mosquitto/mosquitto.conf`
- `mosquitto/passwords`
- `mosquitto/aclfile`

The host-mounted config source directory is:

- default: `./mosquitto`
- override: `${MOSQUITTO_HOST_CONFIG_DIR}`

## Source Of Truth

The broker reads from the host-mounted config source directory and copies those files into `/mosquitto/config` at startup.

Important behavior:

- the host config directory is the only persistent source of truth
- the mount is read-only
- the broker container copies `mosquitto.conf`, `passwords`, and `aclfile` from `/mosquitto/config-src` into `/mosquitto/config`
- edits to host-side auth files do not affect the running broker until the broker is restarted
- edits made only inside the running container do not persist

## Read-Only Mount Rule

The config source mount is intentionally `:ro`.

That means:

- add or change usernames on the host
- add or change password hashes on the host
- add or change ACL rules on the host
- restart the broker after those host-side edits

Do not use the running container as the place where you maintain broker users.

Avoid workflows like:

- editing `/mosquitto/config/passwords` inside the running container
- editing `/mosquitto/config/aclfile` inside the running container
- assuming `docker compose build` alone reloads password or ACL changes

## Files

- `mosquitto/mosquitto.conf`
- `mosquitto/passwords`
- `mosquitto/aclfile`
- `docker-compose.yml`

## Quick Rules

- every publisher should get its own MQTT username and password
- every publisher should get a write-only ACL for its own topic namespace
- every subscriber should get its own MQTT username and password unless you intentionally choose a shared subscriber account
- subscribers should receive only the read ACLs they actually need
- adding one publisher usually means updating two broker files:
  - `mosquitto/passwords`
  - `mosquitto/aclfile`

## Safe Username/Password Workflow

Use this sequence whenever you add a new MQTT account.

1. Edit `mosquitto/passwords` on the host
2. Edit `mosquitto/aclfile` on the host
3. Restart `mqtt-broker`
4. Restart or reconnect any client that should use the new credentials

## Sequence Diagram: Add One Publisher

This diagram shows the safe flow for adding one new publisher account in the current read-only mount design.

```mermaid
sequenceDiagram
    actor Operator
    participant HostAuth as Host auth files<br/>./mosquitto or ${MOSQUITTO_HOST_CONFIG_DIR}
    participant Compose as Docker Compose
    participant Broker as mqtt-broker container
    participant MQTT as Mosquitto runtime
    participant Publisher as Publisher client

    Operator->>HostAuth: Add hashed password entry
    Operator->>HostAuth: Add ACL block for topic write access
    Note over Operator,Broker: The running broker has not reloaded the host edits yet

    Operator->>Compose: restart mqtt-broker
    Compose->>Broker: Restart container startup flow
    Broker->>HostAuth: Read mosquitto.conf, passwords, aclfile
    Broker->>MQTT: Copy files into /mosquitto/config and start broker

    Operator->>Publisher: Start or reconnect client with new username/password
    Publisher->>MQTT: Connect
    MQTT-->>Publisher: Accept if password and ACL match
    Publisher->>MQTT: Publish to allowed topic namespace
```

## Safe Restart Pattern

After editing host-side broker auth files, use:

```bash
docker compose restart mqtt-broker
```

If you are operating a publisher or subscriber outside this fork, restart or reconnect that client after the broker restart if its credentials or access scope changed.

## What Not To Do

- do not add users only inside the container
- do not edit only temporary files inside `/mosquitto/config` and expect them to survive restart or recreate
- do not assume a running broker will notice host-side auth file edits without a restart
- do not restart only clients after changing broker passwords or ACLs and expect the broker to have the new rules loaded

## Add Publishers On Initial Startup

Use this path when the broker is not running yet, or when you are preparing the next clean startup.

### 1. Add the publisher credentials

Append a new line in `mosquitto/passwords`.

Follow the existing format:

```text
publisher-node-4:<hashed-password>
```

Do not store plain-text passwords in this file. It must contain Mosquitto password hashes like the existing entries.

To hash one password with the Mosquitto container tooling, use:

```bash
docker run --rm eclipse-mosquitto:2 \
  sh -c 'mosquitto_passwd -b /tmp/passwords publisher-node-4 publisher-node-4-secret && cat /tmp/passwords'
```

This prints one `username:hash` line that you can copy into `mosquitto/passwords`.

### 2. Add the publisher ACL

Append a new block in `mosquitto/aclfile`.

Example:

```text
user publisher-node-4
topic write sensors/node-4/#
```

This lets that account publish only under `sensors/node-4/...`.

### 3. Start the broker

```bash
docker compose up -d
```

## Add Publishers While The Broker Is Running

This is the safe operational path for the current fork setup.

### What must be restarted

- restart `mqtt-broker` after changing `mosquitto/passwords`
- restart `mqtt-broker` after changing `mosquitto/aclfile`
- restart `mqtt-broker` after changing `mosquitto/mosquitto.conf`

The running broker does not automatically consume edits from the host-side config source because those files are copied into the live config directory only during broker startup.

### Recommended sequence

1. Edit `mosquitto/passwords`
2. Edit `mosquitto/aclfile`
3. Restart `mqtt-broker`
4. Restart or reconnect the affected client

Example:

```bash
docker compose restart mqtt-broker
```

## Add Multiple Publishers At Once

The cleanest pattern is one publisher account per device or logical simulator.

For five new device simulators:

1. add five hashed entries in `mosquitto/passwords`
2. add five ACL blocks in `mosquitto/aclfile`
3. restart `mqtt-broker`
4. reconnect or restart those five clients

Keep each publisher aligned like this:

- MQTT username: `publisher-node-7`
- ACL topic root: `sensors/node-7/#`

That convention makes ACL review and troubleshooting much easier.

## Add A New Metric For An Existing Publisher

Example: add `sensors/node-1/pressure`.

### Needed changes

- no password file change is required if the existing publisher account stays the same
- no ACL change is required if `topic write sensors/node-1/#` already covers the new metric

### Needed only when the ACL is narrower

If you are using a narrower ACL than `sensors/node-1/#`, extend the ACL block in `mosquitto/aclfile` and restart the broker.

## Add A New Subscriber

Use the same pattern as publishers, but define read ACLs instead of write ACLs.

Example restricted subscriber:

```text
user subscriber-temp-only
topic read sensors/+/temp
```

Example broad overview/admin-style subscriber:

```text
user subscriber-admin
topic read #
topic read $SYS/#
```

Be conservative with broad read access.

## Optional External Host Path

To use `/mnt/nvme/mqtt/mosquitto` instead of the repo-local `./mosquitto` directory:

```bash
MOSQUITTO_HOST_CONFIG_DIR=/mnt/nvme/mqtt/mosquitto docker compose up -d
```

## Validation Checklist

After adding or changing broker users, verify:

- `docker compose logs -f mqtt-broker`
- the expected client can connect with the new username/password
- the client can only publish or subscribe to the topic scope allowed by its ACL

## Common Mistakes

- adding a password entry but forgetting the ACL block
- editing host-side files and forgetting to restart the broker
- testing only client reconnect behavior without reloading the broker config
- storing plain-text passwords in `mosquitto/passwords`
