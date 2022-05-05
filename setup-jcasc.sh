#!/bin/bash

TEMP="${RUNNER_TEMP}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

TEMP_JCASC="${TEMP}/casc_configs"
mkdir -p "${TEMP_JCASC}"

SERVICE_JCASC_PATH_JAVAOPT=$(jenkins-cli-groovy 'println(System.getProperty("casc.jenkins.config", ""))')
SERVICE_JCASC_PATH_ENV=$(docker exec "${JENKINS_SERVICE_ID}" printenv CASC_JENKINS_CONFIG)

SERVICE_JCASC_PATH="${SERVICE_JCASC_PATH_JAVAOPT:-${SERVICE_JCASC_PATH_ENV}}"
RELOAD=false

if [ -z "${SERVICE_JCASC_PATH}" ]; then
  # ${JENKINS_HOME}/jenkins.yaml is jcasc default path
  JENKINS_HOME=$(jenkins-cli-groovy 'println(jenkins.model.Jenkins.instance.getRootDir())')
  SERVICE_JCASC_PATH="${JENKINS_HOME}/casc_config/"
  sed "s#@casc_path@#${SERVICE_JCASC_PATH}#g" "${GITHUB_ACTION_PATH}/resources/cascConfigPath.yaml.template" > "${TEMP}/jenkins.yaml"
  docker cp "${TEMP}/jenkins.yaml" "${JENKINS_SERVICE_ID}:${JENKINS_HOME}/jenkins.yaml"
  RELOAD=true
fi

echo '::group::copy jcasc'
if [ -d "${JCASC_PATH}" ]; then
    docker cp "${JCASC_PATH}/." "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"
else
    docker cp "${JCASC_PATH}"   "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"
fi

sed "s#@jenkins_url@#${JENKINS_URL}#g" "${GITHUB_ACTION_PATH}/resources/location.yaml.template" > "${TEMP_JCASC}/location.yaml"
docker cp "${TEMP_JCASC}/." "${JENKINS_SERVICE_ID}:${SERVICE_JCASC_PATH}"

echo "${SERVICE_JCASC_PATH}"
docker exec "${JENKINS_SERVICE_ID}" ls "${SERVICE_JCASC_PATH}"
echo '::endgroup::'

casc_configure() {
  jenkins-cli-groovy 'io.jenkins.plugins.casc.ConfigurationAsCode.get().configure(); jenkins.model.Jenkins.instance.save();'
}

if jenkins-cli list-plugins | grep configuration-as-code; then
  echo '::group::casc configure'
  casc_configure
  echo '::endgroup::'
else
  echo '::group::jenkins-cli install-plugin configuration-as-code'
  jenkins-cli install-plugin configuration-as-code
  echo '::endgroup::'

  # restart
  "${GITHUB_ACTION_PATH}/restart-and-wait.sh"
fi

if "${RELOAD}"; then
  echo '::group::casc configure'
  casc_configure
  echo '::endgroup::'
fi

jenkins-cli-groovy 'casc = jenkins.model.GlobalConfiguration.all().get(io.jenkins.plugins.casc.CasCGlobalConfig.class); cascPath = casc != null ? casc.getConfigurationPath() : ""; println(cascPath)'

jenkins-cli-groovy 'println(io.jenkins.plugins.casc.ConfigurationAsCode.get().getStandardConfig().join(", "))'

# dump
echo '::group::jenkins dump jcasc'
jenkins-cli-groovy 'out = new ByteArrayOutputStream(); io.jenkins.plugins.casc.ConfigurationAsCode.get().export(out); println(out.toString())'
sleep 5
jenkins-log
echo '::endgroup::'
