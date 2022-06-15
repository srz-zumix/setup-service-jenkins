#!/bin/bash

set -euo pipefail

TEMP="${RUNNER_TEMP:-}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

NODE_HOME=/jenkins
REMOTE_FS="${NODE_HOME}/agent"
PREFIX="${TEMP}/jenkins"

mkdir -p "${PREFIX}/agent"

# list exists nodes
EXISTS_NODES=$(jenkins-cli-groovy 'jenkins.model.Jenkins.get().computers.each { println it.displayName }')

function create_node() {
  NODE_NAME=$1
  EXECUTORS=1
  LABELS=
  cat <<EOF | jenkins-cli create-node "${NODE_NAME}"
<slave>
  <name>${NODE_NAME}</name>
  <description></description>
  <remoteFS>${REMOTE_FS}</remoteFS>
  <numExecutors>${EXECUTORS}</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy\$Always" />
  <launcher class="hudson.plugins.sshslaves.JNLPLauncher" />
  <label>${LABELS}</label>
  <nodeProperties>
    <hudson-slaves-EnvironmentVariablesNodeProperty>
      <env>
      </env>
    </hudson-slaves-EnvironmentVariablesNodeProperty>
  </nodeProperties>
</slave>
EOF
}

function agent() {
  echo "$1"

  AGENT_NAME="$1"

  if [[ ! "${EXISTS_NODES}" =~ ${AGENT_NAME} ]]; then
    create_node "${AGENT_NAME}"
  fi

  JENKINS_AGENT_SECRET=$(curl -sSL "${JENKINS_URL}/computer/${AGENT_NAME}/slave-agent.jnlp" | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
  JENKINS_AGENT_ID=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${AGENT_NAME}.id")
  sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
      -e "s#@jenkins_agent_secret@#${JENKINS_AGENT_SECRET}#g" \
      "${GITHUB_ACTION_PATH}/resources/launch-agent.sh.in" \
      > "${PREFIX}/launch-agent.sh"
  chmod +x "${PREFIX}/launch-agent.sh"
  docker cp "${PREFIX}" "${JENKINS_AGENT_ID}:${NODE_HOME}"
  JENKINS_AGENT_STATUS=$(docker inspect --format='{{.State.Status}}' "${JENKINS_AGENT_ID}")
  if [ "${JENKINS_AGENT_STATUS}" == "running" ]; then
    docker exec -d "${JENKINS_AGENT_ID}" "${NODE_HOME}/launch-agent.sh"
  else
    docker inspect "${JENKINS_AGENT_ID}"
    set -x
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "${JENKINS_AGENT_ID}")
    CONTAINER_LABELS=$(docker inspect --format='{{range $k,$v := .Config.Labels}}{{ println --label $k=$v }}{{end}}' "${JENKINS_AGENT_ID}")
    CONATINER_ENVS=$(docker inspect --format='{{range .Config.Env}}{{println -e .}}{{end}}' "${JENKINS_SERVICE_ID}")
    CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' "${JENKINS_AGENT_ID}")

    CONTAINER_NETWORK=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_SERVICE_NAME}.network")

    docker create --name "${CONTAINER_NAME}" "${CONTAINER_LABELS}" --network "${CONTAINER_NETWORK}" --network-alias "${AGENT_NAME}" "${CONATINER_ENVS}" "${CONTAINER_IMAGE}"

    docker run -d "${JENKINS_AGENT_ID}" "${NODE_HOME}/launch-agent.sh"
  fi

  sleep 30
  docker logs "${JENKINS_AGENT_ID}"
}

for node_id in ${JENKINS_NODES}; do
  echo "::group::setup node ${node_id}"
  agent "${node_id}"
  echo '::endgroup::'
done
