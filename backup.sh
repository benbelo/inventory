#!/bin/bash

BACKUP_DIR="/opt/zabbix/backups/Zabbix-BDD"
RETENTION_DAYS=14
DATE=$(date +%Y%m%d_%H%M%S)
COMPOSE_DIR="/opt/zabbix"

DB_CONTAINER="zabbix-db"
DB_NAME="zabbix"
DB_USER="TonUser"
DB_PASS="TonSuperMdp"


# Création du dossier
mkdir -p "$BACKUP_DIR"
LOG="$BACKUP_DIR/backup_$DATE.log"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] - Letsgo - backup Zabbix"

# Dump de la bdd
echo "[$(date)] Dump de la bdd..."
docker exec "$DB_CONTAINER" \
    mariadb-dump -u"$DB_USER" -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "$DB_NAME" | gzip > "$BACKUP_DIR/zabbix_db_$DATE.sql.gz"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "[$(date)] ERREUR : le dump a fail "
    exit 1
fi
echo "[$(date)] Dump OK : zabbix_db_$DATE.sql.gz ($(du -sh "$BACKUP_DIR/zabbix_db_$DATE.sql.gz" | cut -f1))"

# Backup des scripts et configs
echo "[$(date)] Backup des volumes/scripts..."
tar czf "$BACKUP_DIR/zabbix_files_$DATE.tar.gz" \
    -C "$COMPOSE_DIR" \
    docker-compose.yml \
    zabbix_server_alertscripts \
    zabbix_server_externalscripts \
    2>/dev/null

echo "[$(date)] Fichiers OK : zabbix_files_$DATE.tar.gz ($(du -sh "$BACKUP_DIR/zabbix_files_$DATE.tar.gz" | cut -f1))"

# Rotate des anciens backups
echo "[$(date)] Nettoyage des backups > $RETENTION_DAYS jours..."
find "$BACKUP_DIR" -name "zabbix_*" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "backup_*.log" -mtime +$RETENTION_DAYS -delete

# Output echo
echo "[$(date)] === Backup terminé ==="
echo "[$(date)] Contenu du répertoire backup :"
ls -lh "$BACKUP_DIR"/*.gz 2>/dev/null
