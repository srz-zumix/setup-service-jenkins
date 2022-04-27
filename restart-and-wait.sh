#!/bin/bash

echo '::group::jenkins restart'

# get session id
PREV_ID=$(jenkins-cli session-id)

while jenkins-cli session-id | grep "${PREV_ID}"; do
    # restart
    echo "restart request..."
    jenkins-cli restart

    until jenkins-cli session-id 2>/dev/null; do
        sleep 30; echo "waiting jenkins response..."
        docker logs "${JENKINS_SERVICE_ID}"
    done
    echo "checking session-id..."
done

echo '::endgroup::'
