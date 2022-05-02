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

echo '::group::jenkins initialize for JAVA_OPT'

INSPECT_ENVS=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}")
echo "${INSPECT_ENVS}"

JENKINS_JAVA_OPTS=$(echo ${INSPECT_ENVS} | grep JAVA_OPTS= | cut -d'=' -f2-)
echo "${JENKINS_JAVA_OPTS}"

for opt_set in $(echo "${JENKINS_JAVA_OPTS}" | cut -d' '); then
  OPT=$(echo "${opt_set}" | cut -d'=' -f1)
  VAL=$(echo "${opt_set}" | cut -d'=' -f2-)
  echo "${OPT}: ${VAL}"
  if [ "${OPT}" == "java.util.logging.config.file" ]; then
    echo "coppy logging properties" 
    docker cp "${GITHUB_ACTION_PATH}/resources/logging.properties" "${JENKINS_SERVICE_ID}:${VAL}"
  fi
done

echo '::endgroup::'

# restart
"${GITHUB_ACTION_PATH}/restart-and-wait.sh"
