#!/bin/bash

SERVICE_ID=$1
SERVICE_JCASC_PATH=$(jenkins-cli-groovy 'println System.getProperty("casc.jenkins.config")')

if [ -d "${JCASC_PATH}" ]; then
    docker cp "${JCASC_PATH}/." "${SERVICE_ID}:${SERVICE_JCASC_PATH}"
else
    docker cp "${JCASC_PATH}"   "${SERVICE_ID}:${SERVICE_JCASC_PATH}"
fi

echo '::group::jenkins-cli reload-configuration'
jenkins-cli reload-configuration
echo '::endgroup::'
