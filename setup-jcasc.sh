#!/bin/bash

TEMP="${RUNNER_TEMP}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

SERVICE_JCASC_PATH=$(jenkins-cli-groovy 'println System.getProperty("casc.jenkins.config")')

echo '::group::copy jcasc'
if [ -d "${JCASC_PATH}" ]; then
    docker cp "${JCASC_PATH}/." "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"
else
    docker cp "${JCASC_PATH}"   "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"
fi

TEMP_JCASC="${TEMP}/casc_configs"
mkdir -p "${TEMP_JCASC}"
sed "s#@jenkins_url@#${JENKINS_URL}#g" "${GITHUB_ACTION_PATH}/resources/location.yml.template" > "${TEMP_JCASC}/location.yml"

docker cp "${TEMP_JCASC}/." "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"

docker exec "${JENKINS_SERVICE_ID}" ls "${SERVICE_JCASC_PATH}"
echo '::endgroup::'

# echo '::group::jenkins-cli reload-configuration'
# jenkins-cli reload-configuration
# echo '::endgroup::'

# restart
"${GITHUB_ACTION_PATH}/restart-and-wait.sh"

# dump
echo '::group::jenkins dump jcasc'
jenkins-cli-groovy "import io.jenkins.plugins.casc.ConfigurationAsCode; out = new ByteArrayOutputStream(); ConfigurationAsCode.get().export(out); out.toString()"
echo '::endgroup::'
