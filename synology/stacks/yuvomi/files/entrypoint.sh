#!/bin/sh
set -eu

runtimeSecrets=/run/yuvomi-secrets
mkdir -p "$runtimeSecrets"
cp /run/secrets/db_encryption_key "$runtimeSecrets/db_encryption_key"
cp /run/secrets/session_secret "$runtimeSecrets/session_secret"
chown node:node "$runtimeSecrets/db_encryption_key" "$runtimeSecrets/session_secret"
chmod 600 "$runtimeSecrets/db_encryption_key" "$runtimeSecrets/session_secret"

export DB_ENCRYPTION_KEY_FILE="$runtimeSecrets/db_encryption_key"
export SESSION_SECRET_FILE="$runtimeSecrets/session_secret"
exec /entrypoint.sh "$@"
