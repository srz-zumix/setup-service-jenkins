#!/bin/bash

TEMP="${RUNNER_TEMP}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

SERVICE_JCASC_PATH_JAVAOPT=$(jenkins-cli-groovy 'p = System.getProperty("casc.jenkins.config"); if( p != "null" ) println(p)')
SERVICE_JCASC_PATH_ENV=$(docker exec "${JENKINS_SERVICE_ID}" echo '${CASC_JENKINS_CONFIG}')

SERVICE_JCASC_PATH="${SERVICE_JCASC_PATH_JAVAOPT:-${SERVICE_JCASC_PATH_ENV}}"

if [ -z "${SERVICE_JCASC_PATH}" ]; then
  # ${JENKINS_HOME}/jenkins.yml is jcasc default path
  jenkins-cli-groovy 'casc = GlobalConfiguration.all().get(CasCGlobalConfig.class); if(casc != null) println(casc.getConfigurationPath())'
  JENKINS_HOME=$(docker exec "${JENKINS_SERVICE_ID}" echo '${JENKINS_HOME}')
  SERVICE_JCASC_PATH="${JENKINS_HOME}/jenkins.yml/"
fi

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

echo "${SERVICE_JCASC_PATH}"
docker exec "${JENKINS_SERVICE_ID}" ls "${SERVICE_JCASC_PATH}"
echo '::endgroup::'

if jenkins-cli list-plugins | grep configuration-as-code; then
  echo '::group::jenkins-cli reload-configuration'
  jenkins-cli reload-configuration
  echo '::endgroup::'
else
  echo '::group::jenkins-cli install-plugin configuration-as-code'
  jenkins-cli install-plugin configuration-as-code
  echo '::endgroup::'

  # restart
  "${GITHUB_ACTION_PATH}/restart-and-wait.sh"
fi

# dump
echo '::group::jenkins dump jcasc'
jenkins-cli-groovy "out = new ByteArrayOutputStream(); io.jenkins.plugins.casc.ConfigurationAsCode.get().export(out); out.flush(); println(out.toString())"
echo '::endgroup::'
