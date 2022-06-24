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

JENKINS_AGENT_IDS=()
function agent() {
  echo "$1"

  JENKINS_AGENT_NAME="$1"

  if [[ ! "${EXISTS_NODES}" =~ ${JENKINS_AGENT_NAME} ]]; then
    create_node "${JENKINS_AGENT_NAME}"
  fi

  NODE_PREFIX="${PREFIX}/${JENKINS_AGENT_NAME}"
  mkdir -p "${NODE_PREFIX}"

  JENKINS_AGENT_SECRET=$(curl -sSL "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/slave-agent.jnlp" | sed "s/.*<application-desc[^>]*><argument>\([a-z0-9]*\).*/\1/")
  JENKINS_AGENT_ID=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_AGENT_NAME}.id")
  if [ "${JENKINS_AGENT_ID}" == "null" ]; then
    echo "::error ::${JENKINS_AGENT_NAME} service not found."
    return
  fi
  sed -e "s#@jenkins_url@#${JENKINS_URL}#g" \
      -e "s#@jenkins_agent_name@#${JENKINS_AGENT_NAME}#g" \
      -e "s#@jenkins_agent_secret@#${JENKINS_AGENT_SECRET}#g" \
      "${GITHUB_ACTION_PATH}/resources/launch-agent.sh.in" \
      > "${NODE_PREFIX}/launch-agent.sh"
  chmod +x "${NODE_PREFIX}/launch-agent.sh"

  JENKINS_AGENT_STATUS=$(docker inspect --format='{{.State.Status}}' "${JENKINS_AGENT_ID}")
  if [ "${JENKINS_AGENT_STATUS}" == "running" ]; then
    docker cp "${NODE_PREFIX}" "${JENKINS_AGENT_ID}:${NODE_HOME}"
    docker exec -d "${JENKINS_AGENT_ID}" "${NODE_HOME}/launch-agent.sh"
  else
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "${JENKINS_AGENT_ID}")
    CONATINER_LABEL_FILE="${NODE_PREFIX}/label.txt"
    docker inspect --format='{{range $k,$v := .Config.Labels}}{{$k}}="{{$v}}" {{end}}' "${JENKINS_AGENT_ID}" > "${CONATINER_LABEL_FILE}"
    CONTAINER_ENV_FILE="${NODE_PREFIX}/env.txt"
    docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "${JENKINS_AGENT_ID}" > "${CONTAINER_ENV_FILE}"
    CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' "${JENKINS_AGENT_ID}")

    CONTAINER_NETWORK=$(echo "${JOB_SERVICES_CONTEXT_JSON}" | jq -r ".${JENKINS_SERVICE_NAME}.network")

    docker container rm "${CONTAINER_NAME}"
    JENKINS_AGENT_ID=$(docker create --name "${CONTAINER_NAME}" \
      --label-file "${CONATINER_LABEL_FILE}" \
      --network "${CONTAINER_NETWORK}" \
      --network-alias "${JENKINS_AGENT_NAME}" \
      --env-file "${CONTAINER_ENV_FILE}" \
      --entrypoint bash \
      "${CONTAINER_IMAGE}" \
      "${NODE_HOME}/launch-agent.sh" \
      )

    docker cp "${NODE_PREFIX}" "${JENKINS_AGENT_ID}:${NODE_HOME}"
    docker start "${JENKINS_AGENT_ID}"

    JENKINS_AGENT_IDS+=("${JENKINS_AGENT_ID}")
  fi
}

for node_id in ${JENKINS_NODES}; do
  echo "::group::setup node ${node_id}"
  agent "${node_id}"
  echo '::endgroup::'
done

echo "JENKINS_AGENT_IDS=" "${JENKINS_AGENT_IDS[@]}" >> "${GITHUB_ENV}"

function test_agent_online() {
  WAIT_NODE=(cat <<EOF | jenkins-cli groovy =
def onlineNodes = jenkins.model.Jenkins.get().computers.findAll{ it.isOnline() }
"${JENKINS_NODES}".eachLine { if( !onlineNodes.contains(it) ) { println it } }
EOF
)
  if [ -z "${WAIT_NODE}" ]; then
    return 0
  fi
  return 1
}

function wait_agent_online() {
  local attempt_max=5
  local -i attempt_num=1
  while test_agent_online; do    
    if ((attempt_num == attempt_max)); then
        break
    fi
    ((attempt_num++))

    echo "wait launch agent"
    sleep 3
  done
}

set -x
wait_agent_online
