#!/bin/bash

TEMP="${RUNNER_TEMP}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

PREFIX="${TEMP}/jenkins/bin"

mkdir -p "${PREFIX}"
echo "${PREFIX}" >>"${GITHUB_PATH}"

# docker log
sed -e "s#@container_id@#${JENKINS_SERVICE_ID}#g" \
    "${GITHUB_ACTION_PATH}/resources/jenkins-log.in" \
    > "${PREFIX}/jenkins-log"
chmod +x "${PREFIX}/jenkins-log"

INSPECT_ENVS=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}")
echo "${INSPECT_ENVS}"

JENKINS_JAVA_OPTS=$(echo ${INSPECT_ENVS} | grep JAVA_OPTS= | cut -d'=' -f2-)
echo "${JENKINS_JAVA_OPTS}"

if [[ "${JENKINS_JAVA_OPTS}" =~ java.util.logging.config.file ]]; then
  LOGGING_PROPERTIES_FILE=$(echo "${JENKINS_JAVA_OPTS}" | sed 's/.*-Djava.util.logging.config.file=([\S]*).*/\1/g')
  echo "${LOGGING_PROPERTIES_FILE}"
  # coppy logging.properties
  docker cp "${GITHUB_ACTION_PATH}/resources/logging.properties" "${JENKINS_SERVICE_ID}:${LOGGING_PROPERTIES_FILE}"
fi

# restart
"${GITHUB_ACTION_PATH}/restart-and-wait.sh"
