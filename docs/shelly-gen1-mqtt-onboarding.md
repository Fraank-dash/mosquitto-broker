# Shelly Gen1 MQTT Onboarding

This guide shows how to add a Gen1 Shelly device to this broker-only repo.

It is written for the current runtime model in this fork:

- host-side files in `./mosquitto` or `${MOSQUITTO_HOST_CONFIG_DIR}` are the source of truth
- Mosquitto authentication is enabled in `mosquitto/mosquitto.conf`
- device accounts live in `mosquitto/passwords`
- device topic permissions live in `mosquitto/aclfile`
- the broker must be restarted after auth or ACL changes

The examples below keep Shelly's native topic layout:

```text
shellies/<mqtt-id>/...
```

For Gen1 devices, the default MQTT ID is usually:

```text
<shellymodel>-<deviceid>
```

Example:

```text
shellyplug-s-ABC123
```

Keeping the default MQTT ID is the simplest and safest convention unless you have a strong reason to rename it.

## Before You Start

Confirm the broker auth model in this repo:

- `mosquitto/mosquitto.conf` sets `allow_anonymous false`
- `mosquitto/mosquitto.conf` uses `password_file /mosquitto/config/passwords`
- `mosquitto/mosquitto.conf` uses `acl_file /mosquitto/config/aclfile`

Important Shelly Gen1 behavior:

- MQTT is configured on the device through its local web UI or HTTP `/settings`
- enabling MQTT disables Shelly cloud on Gen1 devices
- Gen1 devices do not support secure MQTT/TLS
- the device must be rebooted after MQTT configuration changes

## Recommended Account And Topic Convention

Use one MQTT username and password per Shelly device.

Align each device account to the device's MQTT ID:

- MQTT username: `shellyplug-abc123`
- MQTT ID: `shellyplug-s-ABC123`
- topic root: `shellies/shellyplug-s-ABC123/#`

This keeps ACL review straightforward and avoids topic overlap between devices.

## Shelly Naming Fields

In the Shelly UI you may also see these human-facing fields:

- `Appliance Type`: UI classification for the device type
- `Device Name`: friendly name for the whole device, for example `Office Plug`
- `Channel Name`: friendly name for relay or channel `0`, for example `Desk Lamp`

These names are useful for readability in the Shelly UI and app, but they do not replace the MQTT identity used by this broker unless you explicitly change `mqtt_id`.

For this repo, the recommended split is:

- use `Device Name` and `Channel Name` for human-readable labels
- keep the default `mqtt_id` unless you intentionally want a custom topic identity
- keep ACLs aligned to the actual `mqtt_id`

## Add One Shelly Device

Use this sequence for any Gen1 Shelly device.

If you are using the local helper scripts in this repo, follow the script order described in `docs/secure-broker-howto.md`: password helper first, ACL helper second, then `rsync`, then broker restart.

### 1. Identify the device MQTT ID

On Gen1, the default MQTT ID is `<shellymodel>-<deviceid>`.

You can keep that default, or set a custom `mqtt_id` in the device settings. This guide assumes you keep the default.

Example:

```text
model: shellyplug-s
device ID suffix: ABC123
mqtt_id: shellyplug-s-ABC123
```

### 2. Add the broker password entry

Append one hashed entry to `mosquitto/passwords`.

Format:

```text
<mqtt-username>:<hashed-password>
```

Example:

```text
shellyplug-abc123:<hashed-password>
```

To generate one hashed line with the Mosquitto image:

```bash
docker run --rm eclipse-mosquitto:2 \
  sh -c 'mosquitto_passwd -b /tmp/passwords shellyplug-abc123 change-this-secret && cat /tmp/passwords'
```

Copy the printed `username:hash` line into `mosquitto/passwords`.

### 3. Add the broker ACL block

Append one device-scoped block to `mosquitto/aclfile`.

Recommended shape:

```text
user shellyplug-abc123
topic write shellies/shellyplug-s-ABC123/#
topic read shellies/shellyplug-s-ABC123/relay/0/command
```

Why these rules:

- `topic write shellies/.../#` allows the device to publish its own state, power, energy, announce, and online topics
- `topic read shellies/.../relay/0/command` allows the device to receive on/off/toggle commands from another MQTT client

If you do not intend to control the device through MQTT commands, you can omit the `topic read .../relay/0/command` line.

### 4. Restart the broker

The running broker does not automatically reload host-side auth files in this repo.

After editing `mosquitto/passwords` or `mosquitto/aclfile`, restart the broker:

```bash
docker compose restart mqtt-broker
```

### 5. Configure MQTT on the Shelly device itself

Find the device IP address, open it in a browser, then enable MQTT in the local device UI.

Use these values:

- MQTT enabled: `true`
- broker: `<broker-address>:1883`
- username: the username you added to `mosquitto/passwords`
- password: the plain-text password that matches the stored hash
- MQTT ID: keep default unless you intentionally want a custom ID

For this repo running on the same LAN, the broker value is typically the host IP running this container stack, for example:

```text
192.168.1.20:1883
```

If you manage LAN DNS in Technitium, you can use a DNS name instead:

```text
mqtt.example.lan:1883
```

Do not point the device at `localhost:1883` unless the broker is actually running on the Shelly itself, which it is not.

### 6. Reboot the Shelly device

Gen1 MQTT configuration is applied only after a reboot.

After the reboot, the device should connect and publish its online/status topics.

## Shelly Plug / PlugS Worked Example

This example assumes:

- device model: `Shelly Plug / PlugS`
- device ID: `ABC123`
- default MQTT ID: `shellyplug-s-ABC123`
- broker username: `shellyplug-abc123`
- broker password: `change-this-secret`
- broker IP: `192.168.1.20`

### Broker file changes

Add this line to `mosquitto/passwords`:

```text
shellyplug-abc123:<hashed-password>
```

Add this block to `mosquitto/aclfile`:

```text
user shellyplug-abc123
topic write shellies/shellyplug-s-ABC123/#
topic read shellies/shellyplug-s-ABC123/relay/0/command
```

Restart the broker:

```bash
docker compose restart mqtt-broker
```

### Device-side values in the Shelly UI

Open `http://<device-ip>/` in a browser and enable the MQTT feature in the device's advanced developer settings.

Enter:

- server: `192.168.1.20:1883`
- username: `shellyplug-abc123`
- password: `change-this-secret`
- client ID / MQTT ID: `shellyplug-s-ABC123`
- MQTT enabled: on

Then reboot the device.

If Technitium DNS provides a name for the Raspberry Pi host, you can enter `mqtt.example.lan:1883` instead of the raw IP.

### MQTT topics you should expect

For `Shelly Plug / PlugS`, the official Gen1 MQTT docs describe these useful topics:

- `shellies/shellyplug-s-ABC123/relay/0`
- `shellies/shellyplug-s-ABC123/relay/0/power`
- `shellies/shellyplug-s-ABC123/relay/0/energy`
- `shellies/shellyplug-s-ABC123/relay/0/command`
- `shellies/shellyplug-s-ABC123/online`

Typical behavior:

- `relay/0` reports `on` or `off`
- `relay/0/power` reports instantaneous power in Watts
- `relay/0/energy` reports an incrementing energy counter in Watt-minute
- `relay/0/command` accepts `on`, `off`, or `toggle`
- `online` publishes `true` on connect and the last-will payload is `false`

## HTTP API Example For Gen1

Gen1 Shelly devices also allow MQTT setup through the HTTP `/settings` endpoint.

Example:

```bash
curl "http://192.168.1.55/settings?mqtt_enable=true&mqtt_server=192.168.1.20:1883&mqtt_user=shellyplug-abc123&mqtt_pass=change-this-secret&mqtt_id=shellyplug-s-ABC123"
```

With DNS:

```bash
curl "http://192.168.1.55/settings?mqtt_enable=true&mqtt_server=mqtt.example.lan:1883&mqtt_user=shellyplug-abc123&mqtt_pass=change-this-secret&mqtt_id=shellyplug-s-ABC123"
```

Useful `/settings` parameters for Gen1 MQTT:

- `mqtt_enable`
- `mqtt_server`
- `mqtt_user`
- `mqtt_pass`
- `mqtt_id`
- `mqtt_retain`
- `mqtt_update_period`
- `mqtt_max_qos`

After changing MQTT settings through `/settings`, reboot the device.

## Verify One New Device

After broker restart and device reboot, verify in this order:

### 1. Check broker logs

```bash
docker compose logs -f mqtt-broker
```

You should see the device connect successfully with the configured username.

### 2. Subscribe to the device topics

From another MQTT client, subscribe to the device namespace:

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -u subscriber-topics -P '<subscriber-password>' -t 'shellies/shellyplug-s-ABC123/#' -v
```

You should see traffic such as:

- `shellies/shellyplug-s-ABC123/online true`
- `shellies/shellyplug-s-ABC123/relay/0 off`
- `shellies/shellyplug-s-ABC123/relay/0/power 0`

### 3. Send a test command

Publish a command from a separate MQTT client that has write access to the device command topic:

```bash
mosquitto_pub -h 127.0.0.1 -p 1883 -u shelly-operator -P '<operator-password>' -t 'shellies/shellyplug-s-ABC123/relay/0/command' -m 'toggle'
```

The plug should react, and its state topic should update.

The built-in `subscriber-topics` example in this repo is read-only, so create a separate operator account if you want to publish commands through this broker securely.

## Common Mistakes

- using `localhost:1883` as the broker address on the Shelly instead of the LAN IP of the Docker host
- changing `mosquitto/passwords` or `mosquitto/aclfile` without restarting `mqtt-broker`
- storing a plain-text password in `mosquitto/passwords` instead of a Mosquitto hash
- changing the device MQTT ID but forgetting to update the ACL topic root
- expecting Shelly cloud and MQTT to stay enabled together on Gen1
- expecting TLS or `8883` support from a Gen1 Shelly device
- giving the Shelly write access to broad topics such as `#`

## References

- Shelly Gen1 API and MQTT documentation: `https://shelly-api-docs.shelly.cloud/gen1/`
- Shelly support note on enabling MQTT from the local device interface: `https://support.shelly.cloud/en/support/solutions/articles/103000044280-how-can-i-enable-the-mqtt-feature-`
- This repo's broker operational guide: `docs/secure-broker-howto.md`
