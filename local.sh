#!/bin/bash

set -euo pipefail

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
IMAGE_TAG=latest
PORT=8080
JCASC_PATH=testdata/jcasc
CLEAN=false

RUNNER_TEMP=tmp
GITHUB_PATH=${RUNNER_TEMP}/GITHUB_PATH
GITHUB_ENV=${RUNNER_TEMP}/GITHUB_ENV
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
INSTALL_PLUGINS="job-dsl warnings-ng"

export JENKINS_URL
export JENKINS_SERVICE_ID
export JCASC_PATH
export INSTALL_PLUGINS
export RUNNER_TEMP
export GITHUB_PATH
export GITHUB_ENV
export GITHUB_ACTION_PATH

stop() {
    docker container stop "${JENKINS_SERVICE_ID}" || :
    docker rm "${JENKINS_SERVICE_ID}" || :
}

setpath() {
    GITHUB_PATH_=$(tr '\n' ':' < ${GITHUB_PATH})
    PATH=${GITHUB_PATH_}:${PATH}
    export PATH

    . "${GITHUB_ENV}"
}

mkdir -p "${RUNNER_TEMP}"
echo . > "${GITHUB_PATH}"
echo . > "${GITHUB_ENV}"

stop

docker run -d -p "${PORT}:8080" -p 50000:50000 --name "${JENKINS_SERVICE_ID}" "jenkins/jenkins:${IMAGE_TAG}"

time ./setup-initial.sh
setpath
time ./wait-launch.sh
time ./setup-cli.sh
setpath
time ./install-plugins.sh resources/DefaultJenkinsPlugins.txt
time ./install-plugins.sh testdata/plugins.yml
time ./install-plugins-fromenv.sh
time ./restart-and-wait.sh
time ./setup-jcasc.sh

jenkins-credential -c StringCredentials -i github_token -- -t token
jenkins-credential -c UsernamePasswordCredentials -i hoge_user_pass -- -u hoge -p password
jenkins-credential -c BasicSSHUserPrivateKey -i hoge_ssh_key -- -u hoge -k LICENSE

if [ "${CLEAN}" = "true" ]; then
    stop
fi
