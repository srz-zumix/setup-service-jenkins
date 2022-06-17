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

IMAGE_TAG=latest
PORT=39080
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

JENKINS_SERVICE_NAME=localhost
JENKINS_SERVICE_ID=setup-jenkins
INSTALL_PLUGINS="job-dsl warnings-ng"

JOB_SERVICES_CONTEXT_JSON=$(cat <<EOS
{
    "${JENKINS_SERVICE_NAME}": {
        "id": "${JENKINS_SERVICE_ID}",
        "ports": {
            "50000": "50000",
            "8080": "${PORT}"
        },
        "network": "github_network_92719e37afba4ba1a8cc86fc4131ec94"
    },
    "agent1": {
        "id": "9eb30e83a05b7332762c4c8bf74b3543dfbf911d8c37d49fabf3bd0886a23795",
        "ports": {},
        "network": "github_network_92719e37afba4ba1a8cc86fc4131ec94"
    }
}
EOS
)

export JOB_SERVICES_CONTEXT_JSON
export JENKINS_SERVICE_NAME
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
    GITHUB_PATH_=$(tr '\n' ':' < "${GITHUB_PATH}")
    PATH=${GITHUB_PATH_}:${PATH}
    export PATH
}

mkdir -p "${RUNNER_TEMP}"
echo . > "${GITHUB_PATH}"
echo "CI=true" > "${GITHUB_ENV}"

stop

docker run -d -p "${PORT}:8080" -p 50000:50000 --name "${JENKINS_SERVICE_ID}" "jenkins/jenkins:${IMAGE_TAG}"

time ./setup-initial.sh
setpath
# shellcheck disable=SC2086
. "${GITHUB_ENV}"
export JENKINS_URL
export JENKINS_SERVICE_ID

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
