#!/bin/bash

set -euo pipefail

TEMP="${RUNNER_TEMP:-}"
if [ -z "${TEMP}" ]; then
  TEMP="$(mktemp -d)"
fi

JENKINS_NODES="{{ kitchen_agent_name }}"

# list exists nodes
EXISTS_NODES=$(jenkins-cli-groovy 'jenkins.model.Jenkins.get().computers.each { println it.displayName }')

function create_node() {
  NODE_NAME=$1
  EXECUTORS=1
  cat <<EOF | jenkins-cli create-node "${NODE_NAME}"
<slave>
  <name>${NODE_NAME}</name>
  <description></description>
  <remoteFS>${NODE_HOME}</remoteFS>
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

function agent() {
  echo "$1"

  AGENT_NAME=$(docker exec "$1" uname)

  if [[ ! "${EXISTS_NODES}" =~ ${AGENT_NAME} ]]; then
    # ノードがなかったら作る
    create_node "${AGENT_NAME}"
  fi

  JENKINS_AGENT_SECRET=$(curl -sSL -u "${JENKINS_USER}:${JENKINS_TOKEN}" "${JENKINS_URL}/computer/${AGENT_NAME}/slave-agent.jnlp" | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
}

for node_id in ${JENKINS_NODES}; do
  echo "::group::setup node ${node_id}"
  agent "${node_id}"
  echo '::endgroup::'
done
