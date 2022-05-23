#!/bin/bash

set -euo pipefail

program=$(basename "$0")
readonly program

usage() {
  echo "Usage: ${program}"
  echo "[-t] secret text"
    exit 1
}

while getopts t:h OPT
do
case $OPT in
    t ) SECRET_TEXT=${OPTARG} ;;
    h ) usage ;;
    * ) usage ;;
    esac
done

cat <<EOF
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>${SCOPE}</scope>
  <id>${CREDENTIAL_ID}</id>
  <description>${DESCRIPTION}</description>
  <secret>${SECRET_TEXT}</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF
