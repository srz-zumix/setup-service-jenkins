#!/bin/bash

set -euo pipefail

TEMP="${RUNNER_TEMP:-}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

PREFIX="${TEMP}/jenkins/bin"

mkdir -p "${PREFIX}"

echo '::group::install jenkins-cli wrapper and tools'

echo "${PREFIX}" >>"${GITHUB_PATH}"

curl -sSOL "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
mv jenkins-cli.jar "${PREFIX}/jenkins-cli.jar"

if docker exec "${JENKINS_SERVICE_ID}" test -f /opt/jenkins-plugin-manager.jar > /dev/null; then
  :
else
  echo "install jenkins-plugin-manager.jar"
  PLUGIN_CLI_DOWNLOAD_URL=$(curl -sSL "https://api.github.com/repos/jenkinsci/plugin-installation-manager-tool/releases/latest" | grep browser_download_url | grep jar | cut -d: -f2- | xargs echo)
  curl -sSOL "${PLUGIN_CLI_DOWNLOAD_URL}"
  mv jenkins-plugin-manager-*.jar "${PREFIX}/jenkins-plugin-manager.jar"
  docker cp "${PREFIX}/jenkins-plugin-manager.jar" "${JENKINS_SERVICE_ID}:/opt/jenkins-plugin-manager.jar"
  rm -f "${PREFIX}/jenkins-plugin-manager.jar"
fi

if docker exec "${JENKINS_SERVICE_ID}" which jenkins-plugin-cli > /dev/null; then
  :
else
  cat > "${PREFIX}/jenkins-plugin-cli" <<EOF
#!/bin/bash
exec java -jar /opt/jenkins-plugin-manager.jar "\$@"
EOF
  chmod +x "${PREFIX}/jenkins-plugin-cli"
  docker cp "${PREFIX}/jenkins-plugin-cli" "${JENKINS_SERVICE_ID}:/bin/jenkins-plugin-cli"
  rm -f "${PREFIX}/jenkins-plugin-cli"
fi

sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    -e "s#@jenkins_cli_jar@#${PREFIX}/jenkins-cli.jar#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-cli.in" \
    > "${PREFIX}/jenkins-cli"
chmod +x "${PREFIX}/jenkins-cli"

sed -e "s#@container_id@#${JENKINS_SERVICE_ID}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-plugin-cli.in" \
    > "${PREFIX}/jenkins-plugin-cli"
chmod +x "${PREFIX}/jenkins-plugin-cli"

cp "${GITHUB_ACTION_PATH}/resources/jenkins-cli-groovy" "${PREFIX}/jenkins-cli-groovy"
chmod +x "${PREFIX}/jenkins-cli-groovy"

cp "${GITHUB_ACTION_PATH}/resources/jenkins-cli-groovyfile" "${PREFIX}/jenkins-cli-groovyfile"
chmod +x "${PREFIX}/jenkins-cli-groovyfile"

sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-credential.in" \
    > "${PREFIX}/jenkins-credential"
chmod +x "${PREFIX}/jenkins-credential"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-BasicSSHUserPrivateKey.sh" "${PREFIX}/jenkins-credential-BasicSSHUserPrivateKey.sh"
chmod +x "${PREFIX}/jenkins-credential-BasicSSHUserPrivateKey.sh"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-StringCredentials.sh" "${PREFIX}/jenkins-credential-StringCredentials.sh"
chmod +x "${PREFIX}/jenkins-credential-StringCredentials.sh"
cp "${GITHUB_ACTION_PATH}/resources/jenkins-credential-UsernamePasswordCredentials.sh" "${PREFIX}/jenkins-credential-UsernamePasswordCredentials.sh"
chmod +x "${PREFIX}/jenkins-credential-UsernamePasswordCredentials.sh"

ls -l "${PREFIX}"
echo '::endgroup::'

echo '::group::jenkins-cli help'
"${PREFIX}/jenkins-cli" help
echo '::endgroup::'

echo '::group::jenkins-plugin-cli help'
"${PREFIX}/jenkins-plugin-cli" --help
echo '::endgroup::'
