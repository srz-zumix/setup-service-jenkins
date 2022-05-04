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


echo '::group::docker inspect jenkins'
docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}"
echo '::endgroup::'

echo '::group::docker logs'
"${PREFIX}/jenkins-log"
echo '::endgroup::'

echo '::group::jenkins initialize for JAVA_OPT'

JENKINS_JAVA_OPTS=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_SERVICE_ID}" | grep JAVA_OPTS= | cut -d'=' -f2-)
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
docker container restart "${JENKINS_SERVICE_ID}"
sleep 30
# "${GITHUB_ACTION_PATH}/restart-and-wait.sh"
