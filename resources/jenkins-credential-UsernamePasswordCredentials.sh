#!/bin/bash

set -euo pipefail

program=$(basename "$0")
readonly program

usage() {
  echo "Usage: ${program}"
  echo "[-p] password"
  echo "[-u] username"
    exit 1
}

while getopts p:u:h OPT
do
case $OPT in
    p ) PASSWORD=${OPTARG} ;;
    u ) USERNAME=${OPTARG} ;;
    h ) usage ;;
    * ) usage ;;
    esac
done

cat <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>${SCOPE}</scope>
  <id>${CREDENTIAL_ID}</id>
  <description>${DESCRIPTION}</description>
  <username>${USERNAME}</username>
  <password>${PASSWORD}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
