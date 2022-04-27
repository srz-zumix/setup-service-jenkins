#!/bin/bash

echo '::group::jenkins restart'

# get session id
PREV_ID=$(jenkins-cli session-id)

wait() {
    local attempt_max=4
    local -i attempt_num=1
    until jenkins-cli session-id 2>/dev/null; do
        sleep 30; echo "waiting jenkins response..."
        if ((attempt_num == attempt_max)); then
            docker logs "${JENKINS_SERVICE_ID}"
            docker container restart "${JENKINS_SERVICE_ID}"
        else
            if ((attempt_num == attempt_max*2)); then
                docker logs "${JENKINS_SERVICE_ID}"
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

    echo "checking session-id..."
done

echo '::endgroup::'
