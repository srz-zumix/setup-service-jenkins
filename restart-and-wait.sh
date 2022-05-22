#!/bin/bash

set -euo pipefail

echo '::group::jenkins restart'

# get session id
PREV_ID=$(jenkins-cli session-id)

restart_container() {
    # jenkins-log
    docker container restart "${JENKINS_SERVICE_ID}"
    echo 'container restart'
}

wait() {
    local attempt_max=5
    local -i attempt_num=1
    until jenkins-cli session-id 2>/dev/null; do
        sleep 20; echo "waiting jenkins response..."
        if ((attempt_num == 1)); then
            restart_container
        else
            STATUS=$(docker inspect --format='{{.State.Status}}' "${JENKINS_SERVICE_ID}")
            if [ "${STATUS}" == "dead" ] || [ "${STATUS}" == "existed" ]; then
                restart_container
            fi
            if ((attempt_num == attempt_max)); then
                jenkins-log
                exit 1
            fi
        fi
        ((attempt_num++))
    done
}

while jenkins-cli session-id | grep "${PREV_ID}"; do
    # restart
    echo "restart request..."
    jenkins-cli restart

    wait
done

echo '::endgroup::'
