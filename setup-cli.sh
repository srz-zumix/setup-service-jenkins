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

cp "${GITHUB_ACTION_PATH}/resources/jenkins-cli.in" "${PREFIX}/jenkins-cli"
sed -i "s#@jenkins_url@#${JENKINS_URL}#g" "${PREFIX}/jenkins-cli"
sed -i "s#@jenkins_cli_jar@#${PREFIX}/jenkins-cli.jar#g" "${PREFIX}/jenkins-cli"
chmod +x "${PREFIX}/jenkins-cli"

echo '::group::jenkins-cli help'
"${PREFIX}/jenkins-cli" help
echo '::endgroup::'
