#!/bin/bash

TEMP="${RUNNER_TEMP}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

mkdir -p "${TEMP}/jenkins/bin"

curl -sSOL "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
mv jenkins-cli.jar "${TEMP}/jenkins/bin"

echo "${TEMP}/jenkins/bin" >>"${GITHUB_PATH}"
