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

# coppy logging.properties
docker cp "${GITHUB_ACTION_PATH}/resources/logging.properties" "${JENKINS_SERVICE_ID}:/var/lib/jenkins/logging.properties"
