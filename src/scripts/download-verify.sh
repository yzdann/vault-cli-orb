#!/bin/bash
#!/usr/bin/env bash

# https://circleci.com/docs/using-shell-scripts/#set-error-flags
set -o nounset
set -o errexit

CURRENT_HASHICORP_PGP_KEYID="72D7468F"
VAULT_SYS_ENV_PLATFORM="linux_amd64"

VAULT_VER_STRING=$(curl -fs https://api.releases.hashicorp.com/v1/releases/vault/latest | jq -r '.version')

# vault filenames
VAULT_RELEASE_VERSION_NAME="vault_${VAULT_VER_STRING}"
VAULT_ENV_RELEASE_VERSION_NAME="${VAULT_RELEASE_VERSION_NAME}_${VAULT_SYS_ENV_PLATFORM}"
VAULT_RELEASE_SHA256SUM="${VAULT_RELEASE_VERSION_NAME}_SHA256SUMS"
VAULT_RELEASE_SHA256SUM_SIG="${VAULT_RELEASE_SHA256SUM}.${CURRENT_HASHICORP_PGP_KEYID}.sig"

# vault URL
VAULT_RELEASE_URL="https://releases.hashicorp.com/vault/${VAULT_VER_STRING}"
VAULT_BINARY_URL="${VAULT_RELEASE_URL}/${VAULT_ENV_RELEASE_VERSION_NAME}.zip"
VAULT_SHA256SUM_URL="${VAULT_RELEASE_URL}/${VAULT_RELEASE_SHA256SUM}"
VAULT_SHA256SUM_SIG_URL="${VAULT_RELEASE_URL}/${VAULT_RELEASE_SHA256SUM_SIG}"

for link in "$VAULT_BINARY_URL" "$VAULT_SHA256SUM_URL" "$VAULT_SHA256SUM_SIG_URL";
do
  curl -sSL "${link}" --fail --retry 3 -O
done

# https://www.hashicorp.com/security
# Verify if we are using correct 
gpg --show-keys "${HOME}/hashicorp.asc" | grep $CURRENT_HASHICORP_PGP_KEYID

# Verify current version SHA256SUM
gpg --verify "$VAULT_RELEASE_SHA256SUM_SIG" "$VAULT_RELEASE_SHA256SUM"

# Verify binary
sha256sum --ignore-missing -c "$VAULT_RELEASE_SHA256SUM"

unzip -q -o "${VAULT_ENV_RELEASE_VERSION_NAME}.zip"

# cleanup downloaded files
rm "${VAULT_ENV_RELEASE_VERSION_NAME}.zip" "$VAULT_RELEASE_SHA256SUM" "$VAULT_RELEASE_SHA256SUM_SIG"