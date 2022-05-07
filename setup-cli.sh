#!/bin/bash

TEMP="${RUNNER_TEMP}"
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

echo '::group::jenkins-cli help'
"${PREFIX}/jenkins-cli" help
echo '::endgroup::'
