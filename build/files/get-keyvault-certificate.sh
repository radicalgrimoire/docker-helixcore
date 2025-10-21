#!/bin/bash

# usage) get-keyvault-certificate.sh my-keyvault fukasawah-dev

set -ue

umask 027

GROUP=nginx

KEYVAULT_NAME=${1}
CERTIFICATE_NAME=${2}

OUTPUT_DIR=${3:-/etc/letsencrypt}

TMP_DIR="/var/tmp/get-keyvault-certificate-$$"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"


mkdir "$TMP_DIR"

function tear_down(){
    rm -rf "$TMP_DIR"
    exit
}

trap "tear_down" EXIT


TMP_CERT_DIR="${TMP_DIR}/${CERTIFICATE_NAME}"
TMP_DUMP_PFX="${TMP_DIR}/dump.pfx"

# Get PKCS12 File from KeyVault
ACCESS_TOKEN=$(curl --fail -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?resource=https://vault.azure.net&api-version=2018-02-01" | python -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')

SECRET_URL="https://${KEYVAULT_NAME}.vault.azure.net/secrets/${CERTIFICATE_NAME}/?api-version=2016-10-01"

curl --fail -H "Authorization: Bearer $ACCESS_TOKEN" "$SECRET_URL" | python -c 'import sys,json; print(json.load(sys.stdin)["value"])' | base64 -id > "${TMP_DUMP_PFX}"


# Convert to PEM
mkdir "$TMP_CERT_DIR"

# Private Key
openssl pkcs12 -in "${TMP_DUMP_PFX}" -nocerts -password "pass:" -nodes -out "${TMP_CERT_DIR}/privkey.pem"
# CA CERT
openssl pkcs12 -in "${TMP_DUMP_PFX}" -cacerts -password "pass:" -nokeys -out "${TMP_CERT_DIR}/chain.pem"
# Cert
openssl pkcs12 -in "${TMP_DUMP_PFX}" -clcerts -password "pass:" -nokeys -out "${TMP_CERT_DIR}/cert.pem"
# Fullchain
cat "${TMP_CERT_DIR}/cert.pem" "${TMP_CERT_DIR}/chain.pem" > "${TMP_CERT_DIR}/fullchain.pem"

#chmod 0440 "${TMP_CERT_DIR}/"*".pem"

# Verify

KEY_MD5=$(openssl rsa -noout -modulus -in "${TMP_CERT_DIR}/privkey.pem" | openssl md5)
CERT_MD5=$(openssl x509 -noout -modulus -in "${TMP_CERT_DIR}/cert.pem" | openssl md5)

if [ "$KEY_MD5" != "$CERT_MD5" ]; then
    echo "Failed verification. ($KEY_MD5 != $CERT_MD5)" >&2
    exit 1
fi


LIVE_DIR="${OUTPUT_DIR}/live"
NAMED_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

mkdir -p "${OUTPUT_DIR}"

if [ -f "${LIVE_DIR}/${CERTIFICATE_NAME}/cert.pem" ]; then

    CERT_TEXT_MD5=$(openssl x509 -text -noout -in "${TMP_CERT_DIR}/cert.pem")
    LIVE_CERT_TEXT_MD5=$(openssl x509 -text -noout -in "${LIVE_DIR}/${CERTIFICATE_NAME}/cert.pem")

    if [ "$CERT_TEXT_MD5" = "$LIVE_CERT_TEXT_MD5" ]; then
        echo "Unchanged." >&2
        exit 0
    fi
fi

mkdir "$NAMED_DIR"

# move to OUTPUT_DIR

mv "${TMP_CERT_DIR}" "${NAMED_DIR}/${CERTIFICATE_NAME}"

ln -nfs "${NAMED_DIR}" "${LIVE_DIR}"
