#!/bin/bash

jenkins-cli-groovy println 'println System.getProperty("casc.jenkins.config")'

SERVICE_ID=$1
SERVICE_JCASC_PATH=/var/jenkins_home/casc_configs

if [ -d "${JCASC_PATH}" ]; then
    docker cp "${SERVICE_ID}:${SERVICE_JCASC_PATH}" "${JCASC_PATH}/."
else
    docker cp "${SERVICE_ID}:${SERVICE_JCASC_PATH}" "${JCASC_PATH}"
fi

echo '::group::jenkins-cli reload-configuration'
jenkins-cli reload-configuration
echo '::endgroup::'
