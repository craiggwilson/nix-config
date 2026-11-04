#!/bin/sh
set -eu

ACME_HOME=/usr/local/share/acme.sh
ACME="$ACME_HOME/acme.sh"
SECRET_DIR=/volume3/docker/certificates/secrets

if [ ! -x "$ACME" ]; then
  echo "acme.sh is not installed at $ACME" >&2
  exit 1
fi

export NAMECHEAP_API_KEY=$(cat "$SECRET_DIR/namecheap_api_key")
export NAMECHEAP_SOURCEIP=$(cat "$SECRET_DIR/namecheap_source_ip")
export NAMECHEAP_USERNAME=$(cat "$SECRET_DIR/namecheap_username")

exec "$ACME" --renew-all --home "$ACME_HOME" --server letsencrypt
