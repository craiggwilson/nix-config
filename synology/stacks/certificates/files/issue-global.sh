#!/bin/sh
set -eu

ACME_HOME=/usr/local/share/acme.sh
ACME="$ACME_HOME/acme.sh"
SECRET_DIR=/volume3/docker/certificates/secrets
CERT_DOMAIN='*.wilsonfamilyhq.com'
CERT_ALT_DOMAIN='*.raeford.wilsonfamilyhq.com'

if [ ! -x "$ACME" ]; then
  echo "acme.sh is not installed at $ACME" >&2
  exit 1
fi

export NAMECHEAP_API_KEY=$(cat "$SECRET_DIR/namecheap_api_key")
export NAMECHEAP_SOURCEIP=$(cat "$SECRET_DIR/namecheap_source_ip")
export NAMECHEAP_USERNAME=$(cat "$SECRET_DIR/namecheap_username")

"$ACME" --issue \
  --dns dns_namecheap \
  --home "$ACME_HOME" \
  --keylength ec-256 \
  --server letsencrypt \
  -d "$CERT_DOMAIN" \
  -d "$CERT_ALT_DOMAIN"

SYNO_CERTIFICATE="WilsonFamilyHQ" \
SYNO_CREATE=1 \
SYNO_LOCAL_HOSTNAME=1 \
SYNO_USE_TEMP_ADMIN=1 \
  "$ACME" --deploy \
    --deploy-hook synology_dsm \
    --home "$ACME_HOME" \
    -d "$CERT_DOMAIN"
