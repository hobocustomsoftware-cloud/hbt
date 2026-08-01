#!/bin/sh
# HBT Backup Sync Script
# Syncs local backups to cloud storage (S3-compatible)
# Run AFTER backup-postgres.sh succeeds
set -eu

: "${HBT_S3_BUCKET:?HBT_S3_BUCKET is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${HBT_BACKUP_DIR:?HBT_BACKUP_DIR is required}"

# Configuration
S3_ENDPOINT="${HBT_S3_ENDPOINT:-}"
S3_REGION="${HBT_S3_REGION:-auto}"
S3_STORAGE_CLASS="${HBT_S3_STORAGE_CLASS:-STANDARD_IA}"
S3_RETENTION_DAYS="${HBT_S3_RETENTION_DAYS:-30}"
S3_MONTHLY_RETENTION="${HBT_S3_MONTHLY_RETENTION:-365}"

# S3 CLI: support both aws-cli and s3cmd
S3_CLI="${HBT_S3_CLI:-aws}"

if [ "$S3_CLI" = "aws" ]; then
    S3_CMD="aws s3"
    if [ -n "$S3_ENDPOINT" ]; then
        S3_CMD="$S3_CMD --endpoint-url $S3_ENDPOINT"
    fi
else
    S3_CMD="s3cmd"
fi

# Sync latest backup to S3
echo "Syncing backups to S3: s3://$HBT_S3_BUCKET/$POSTGRES_DB/"
$S3_CMD sync \
    "$HBT_BACKUP_DIR/" \
    "s3://$HBT_S3_BUCKET/$POSTGRES_DB/" \
    --storage-class "$S3_STORAGE_CLASS" \
    --region "$S3_REGION" \
    --no-progress \
    --exclude "*.tmp"

# Clean old backups from S3 (daily backups older than retention)
if [ "$S3_CLI" = "aws" ]; then
    $S3_CMD ls "s3://$HBT_S3_BUCKET/$POSTGRES_DB/" | while read -r line; do
        date_str=$(echo "$line" | awk '{print $1 " " $2}')
        file_name=$(echo "$line" | awk '{print $4}')
        
        # Skip if not a .dump file
        case "$file_name" in
            *.dump.gz|*.dump) ;;
            *) continue ;;
        esac
        
        file_ts=$(date -d "$date_str" +%s 2>/dev/null || echo 0)
        now_ts=$(date +%s)
        age_days=$(( (now_ts - file_ts) / 86400 ))
        
        # Keep monthly backups longer
        if echo "$file_name" | grep -q "01T"; then
            # First of month backup — keep for monthly retention
            if [ "$age_days" -gt "$S3_MONTHLY_RETENTION" ]; then
                $S3_CMD rm "s3://$HBT_S3_BUCKET/$POSTGRES_DB/$file_name"
                echo "Removed monthly backup: $file_name (age: ${age_days}d)"
            fi
        elif [ "$age_days" -gt "$S3_RETENTION_DAYS" ]; then
            $S3_CMD rm "s3://$HBT_S3_BUCKET/$POSTGRES_DB/$file_name"
            echo "Removed daily backup: $file_name (age: ${age_days}d)"
        fi
    done
fi

echo "Backup sync complete: $(date -u)"
