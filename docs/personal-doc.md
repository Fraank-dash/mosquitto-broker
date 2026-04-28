# Set PW

1. In KeePass mqtt-user-name anlegen und mqtt-passwort ohne sonderzeichen generieren
2. Je generiertem Usernamen

> ./scripts/mosquitto-hash-password.sh <mqtt-user-name> <mqtt-password> ./mosquitto/passwords

-> wird in mosquitto-broker/mosquitto/passwords hinzugefügt oder ersetzt

# Topics

zum usernamen die Topics in 
> mosquitto-broker/mosquitto/aclfile pflegen

# Sync

> ./scripts/rsync-mosquitto-to-pi.sh --host 192.168.178.58 --user fraank --remote-dir /mnt/nvme/mqtt

# Docker neustarten 

>docker compose restart mqtt-broker

# Sanity check

>docker compose logs -f mqtt-broker 