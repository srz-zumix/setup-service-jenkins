#!/bin/bash

set -euo pipefail

TEMP="${RUNNER_TEMP:-}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

PREFIX="${TEMP}/jenkins/bin"

mkdir -p "${PREFIX}"
echo "${PREFIX}" >> "${GITHUB_PATH}"

# CONTAINER_NETWORK=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_SERVICE_NAME}.network")
# docker network inspect "${CONTAINER_NETWORK}" || :

JENKINS_SERVICE_ID=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_SERVICE_NAME}.id")
JENKINS_SERVICE_PORT=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_SERVICE_NAME}.ports[\"8080\"]")
JENKINS_URL="http://${JENKINS_SERVICE_NAME}:${JENKINS_SERVICE_PORT}"
if [ -f /.dockerenv ]; then
  :
else
  JENKINS_SERVICE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${JENKINS_SERVICE_ID}")
  # JENKINS_URL="http://${JENKINS_SERVICE_IP}:${JENKINS_SERVICE_PORT}"
  if [ "${JENKINS_SERVICE_NAME}" != "localhost" ]; then
    sudo echo "${JENKINS_SERVICE_IP} ${JENKINS_SERVICE_NAME}" | sudo tee -a /etc/hosts
  fi
fi

{
  echo "JENKINS_URL=${JENKINS_URL}"
  echo "JENKINS_SERVICE_ID=${JENKINS_SERVICE_ID}"
  echo "JENKINS_SERVICE_NAME=${JENKINS_SERVICE_NAME}"
  echo "JENKINS_SERVICE_PORT=${JENKINS_SERVICE_PORT}"
} >> "${GITHUB_ENV}"

echo '::group::detect jenkins service config'

docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}"
docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}" | grep -v -e LANG -e JAVA_OPTS -e PATH -e JAVA_HOME > "${TEMP}/jenkins-env"
# shellcheck source=/dev/null
. "${TEMP}/jenkins-env"
echo '::endgroup::'

echo '::group::init'
JENKINS_SHRE_REF=${REF:-/usr/share/jenkins/ref}
if [ -z "${JENKINS_VERSION}" ]; then
  JENKINS_VERSION=$(docker exec "${JENKINS_SERVICE_ID}" java -jar "${JENKINS_SHRE_REF}/../jenkins.war" --version)
fi

# skip setup wizard
echo "jenkins versioin: ${JENKINS_VERSION}"
echo "${JENKINS_VERSION}" > "${TEMP}/jenkins-version.txt"
docker cp "${GITHUB_ACTION_PATH}/resources/init.groovy.d/setup-jenkins-init.groovy" "${JENKINS_SERVICE_ID}:${JENKINS_SHRE_REF}/init.groovy.d/setup-jenkins-init.groovy"

docker cp "${TEMP}/jenkins-version.txt" "${JENKINS_SERVICE_ID}:${JENKINS_SHRE_REF}/jenkins.install.UpgradeWizard.state"
docker cp "${TEMP}/jenkins-version.txt" "${JENKINS_SERVICE_ID}:${JENKINS_SHRE_REF}/jenkins.install.InstallUtil.lastExecVersion"

echo '::endgroup::'

echo '::group::install tools'
# docker log
sed -e "s#@container_id@#${JENKINS_SERVICE_ID}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-log.in" \
    > "${PREFIX}/jenkins-log"
chmod +x "${PREFIX}/jenkins-log"

# jenkins build log
sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-build-log.in" \
    > "${PREFIX}/jenkins-build-log"
chmod +x "${PREFIX}/jenkins-build-log"

# jenkins download artifacts
sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-download-artifact.in" \
    > "${PREFIX}/jenkins-download-artifact"
chmod +x "${PREFIX}/jenkins-download-artifact"

ls -l "${PREFIX}"
echo '::endgroup::'

echo '::group::docker logs'
"${PREFIX}/jenkins-log"
echo '::endgroup::'

echo '::group::jenkins initialize for JAVA_OPT'

JENKINS_JAVA_OPTS=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}" | grep JAVA_OPTS= | cut -d'=' -f2- || : )
for opt_set in ${JENKINS_JAVA_OPTS}; do
  OPT=$(echo "${opt_set}" | cut -d'=' -f1)
  VAL=$(echo "${opt_set}" | cut -d'=' -f2-)
  # echo "${OPT}: ${VAL}"
  if [ "${OPT}" == "-Djava.util.logging.config.file" ]; then
    echo "coppy logging properties: ${VAL}" 
    docker cp "${GITHUB_ACTION_PATH}/resources/logging.properties" "${JENKINS_SERVICE_ID}:${VAL}"
  fi
done
echo '::endgroup::'

# restart
echo '::group::container restart'

LOG_PATH=$(docker inspect "${JENKINS_SERVICE_ID}" --format='{{.LogPath}}')
sudo truncate -s 0 "${LOG_PATH}" || :

docker container restart "${JENKINS_SERVICE_ID}"
# "${GITHUB_ACTION_PATH}/restart-and-wait.sh"
echo '::endgroup::'
