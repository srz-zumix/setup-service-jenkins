#!/bin/bash

set -euo pipefail

TEMP="${RUNNER_TEMP:-}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

PREFIX="${TEMP}/jenkins/bin"

mkdir -p "${PREFIX}"

curl -sSOL "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
mv jenkins-cli.jar "${PREFIX}/jenkins-cli.jar"

echo "${PREFIX}" >>"${GITHUB_PATH}"

sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    -e "s#@jenkins_cli_jar@#${PREFIX}/jenkins-cli.jar#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-cli.in" \
    > "${PREFIX}/jenkins-cli"
chmod +x "${PREFIX}/jenkins-cli"

cp "${GITHUB_ACTION_PATH}/resources/jenkins-cli-groovy" "${PREFIX}/jenkins-cli-groovy"
chmod +x "${PREFIX}/jenkins-cli-groovy"

cp "${GITHUB_ACTION_PATH}/resources/jenkins-cli-groovyfile" "${PREFIX}/jenkins-cli-groovyfile"
chmod +x "${PREFIX}/jenkins-cli-groovyfile"

sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-credential.in" \
    > "${PREFIX}/jenkins-credential"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-BasicSSHUserPrivateKey.sh" "${PREFIX}/jenkins-credential-BasicSSHUserPrivateKey.sh"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-StringCredentials.sh" "${PREFIX}/jenkins-credential-StringCredentials.sh"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-UsernamePasswordCredentials.sh" "${PREFIX}/jenkins-credential-UsernamePasswordCredentials.sh"
chmod +x "${PREFIX}/jenkins-credential"

echo '::group::jenkins-cli help'
"${PREFIX}/jenkins-cli" help
echo '::endgroup::'
