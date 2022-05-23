#!/bin/bash

set -euo pipefail

program=$(basename "$0")
readonly program

usage() {
  echo "Usage: ${program}"
  echo "[-k] private key file"
  echo "[-p] passphrase"
  echo "[-u] username"
    exit 1
}

PASSPHRASE=
while getopts k:p:u:h OPT
do
case $OPT in
    k ) PRIVATE_KEY_FILE=${OPTARG} ;;
    p ) PASSPHRASE=${OPTARG} ;;
    u ) USERNAME=${OPTARG} ;;
    h ) usage ;;
    * ) usage ;;
    esac
done

PRIVATE_KEY=$(cat "${PRIVATE_KEY_FILE}")
cat <<EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
  <scope>${SCOPE}</scope>
  <id>${CREDENTIAL_ID}</id>
  <description>${DESCRIPTION}</description>
  <username>${USERNAME}</username>
  <passphrase>${PASSPHRASE}</passphrase>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
    <privateKey>${PRIVATE_KEY}</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

