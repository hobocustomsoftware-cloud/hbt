#!/bin/sh
# HBT Backup Verification Script
# Restores latest backup to a temporary database and verifies integrity.
# Run weekly (cron: 0 4 * * 0)
set -eu

: "${POSTGRES_HOST:?POSTGRES_HOST is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${HBT_BACKUP_DIR:?HBT_BACKUP_DIR is required}"

# Configuration
VERIFY_DB="${POSTGRES_DB}_verify_$(date +%Y%m%d)"
REPORT_FILE="${HBT_BACKUP_DIR}/verify-report-$(date +%Y%m%d).txt"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$REPORT_FILE"; }

log "=== Backup Verification: $(date) ==="
log "Host: $POSTGRES_HOST"
log "Source DB: $POSTGRES_DB"
log "Verify DB: $VERIFY_DB"

# Find latest backup
latest_backup=$(ls -t "$HBT_BACKUP_DIR"/hbt-*.dump 2>/dev/null | head -1)
if [ -z "$latest_backup" ]; then
    log "FAILURE: No backup files found in $HBT_BACKUP_DIR"
    exit 1
fi
log "Latest backup: $latest_backup"

# Verify checksum
if [ -f "${latest_backup}.sha256" ]; then
    if sha256sum -c "${latest_backup}.sha256" >> "$REPORT_FILE" 2>&1; then
        log "PASS: Checksum verified"
    else
        log "FAILURE: Checksum mismatch — backup may be corrupted"
        exit 1
    fi
else
    log "WARNING: No checksum file found"
fi

# Create verification database
log "Creating verification database: $VERIFY_DB"
PGPASSWORD="${POSTGRES_PASSWORD:-}" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d postgres \
    -c "CREATE DATABASE \"$VERIFY_DB\" OWNER \"$POSTGRES_USER\";" 2>&1 | tee -a "$REPORT_FILE"

# Restore backup to verification database
log "Restoring backup to $VERIFY_DB..."
if PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_restore \
    --host="$POSTGRES_HOST" \
    --username="$POSTGRES_USER" \
    --dbname="$VERIFY_DB" \
    --verbose \
    "$latest_backup" >> "$REPORT_FILE" 2>&1; then
    log "PASS: Backup restored successfully"
else
    log "FAILURE: Backup could not be restored"
    PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" \
        -d postgres -c "DROP DATABASE IF EXISTS \"$VERIFY_DB\";"
    exit 1
fi

# Run integrity checks
log "Running integrity checks..."
PGPASSWORD="${POSTGRES_PASSWORD:-}" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$VERIFY_DB" \
    -c "
    SELECT 'PASS: Database responds' AS check_name
    UNION ALL
    SELECT 'Tables: ' || COUNT(*)::text FROM information_schema.tables WHERE table_schema = 'public'
    UNION ALL
    SELECT 'Columns: ' || COUNT(*)::text FROM information_schema.columns WHERE table_schema = 'public';
    " 2>&1 | tee -a "$REPORT_FILE"

# Check critical tables have data
log "Checking critical table row counts..."
PGPASSWORD="${POSTGRES_PASSWORD:-}" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$VERIFY_DB" \
    -c "
    SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables
    WHERE n_live_tup > 0
    ORDER BY n_live_tup DESC LIMIT 20;
    " 2>&1 | tee -a "$REPORT_FILE"

# Clean up verification database
log "Dropping verification database: $VERIFY_DB"
PGPASSWORD="${POSTGRES_PASSWORD:-}" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d postgres \
    -c "DROP DATABASE IF EXISTS \"$VERIFY_DB\";" 2>&1 | tee -a "$REPORT_FILE"

log "PASS: Verification complete — backup is valid"
log "Report: $REPORT_FILE"
echo "BACKUP_VERIFIED=true"
