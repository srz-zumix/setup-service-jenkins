#!/bin/bash

# coppy logging.properties
docker cp "${GITHUB_ACTION_PATH}/resources/logging.properties" "${JENKINS_SERVICE_ID}:/var/lib/jenkins/logging.properties"
