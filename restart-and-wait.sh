#!/bin/bash

echo '::group::jenkins restart'

# get session id
PREV_ID=$(jenkins-cli session-id)
echo "${PREV_ID}"

while jenkins-cli session-id | grep "${PREV_ID}"; do
    # restart
    echo "restart request..."
    jenkins-cli restart

    until jenkins-cli session-id 2>/dev/null; do
        sleep 30; echo "waiting jenkins response..."
    done
    echo "checking session-id..."
done

echo '::endgroup::'
