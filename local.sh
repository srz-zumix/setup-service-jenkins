#!/bin/bash

set -euox pipefail

program=$(basename "$0")
readonly program

usage() {
  echo "Usage: ${program}"
  echo "[-c] stop adn rm container"
  echo "[-p] container port"
  echo "[-t] jenkins image tag"
    exit 1
}

JENKINS_SERVICE_ID=setup-jenkins
IMAGE_TAGE=latest
PORT=8080
JCASC_PATH=testdata/jcasc
CLEAN=false

RUNNER_TEMP=tmp
GITHUB_PATH=${RUNNER_TEMP}/GITHUB_PATH
GITHUB_ACTION_PATH=.

while getopts c:p:t:xh OPT
do
case $OPT in
    c ) JCASC_PATH=${OPTARG} ;;
    p ) PORT=${OPTARG} ;;
    t ) IMAGE_TAG=${OPTARG} ;;
    x ) CLEAN=true ;;
    h ) usage ;;
    * ) usage ;;
    esac
done

JENKINS_URL="http://localhost:${PORT}"

stop() {
    docker container stop "${JENKINS_SERVICE_ID}" || :
    docker rm "${JENKINS_SERVICE_ID}" || :
}

setpath() {
    GITHUB_PATH_=$(tr '\n' ':' < ${GITHUB_PATH})
    PATH=${GITHUB_PATH_}:${PATH}
    export PATH
}

mkdir -p "${RUNNER_TEMP}"
echo . > "${GITHUB_PATH}"

stop

docker run -d -p "${PORT}:8080" -p 50000:50000 --name "${JENKINS_SERVICE_ID}" "jenkins/jenkins:${IMAGE_TAGE}"

. ./setup-initial.sh
setpath
echo ${PATH}
. ./wait-launch.sh
. ./setup-cli.sh
setpath
. ./install-plugins.sh resources/DefaultJenkinsPlugins.txt
INSTALL_PLUGINS="job-dsl warnings-ng"
. ./install-plugins-fromenv
. ./restart-and-wait.sh
. ./setup-jcasc.sh

if [ "${CLEAN}" -eq "true" ]; then
    stop
fi
