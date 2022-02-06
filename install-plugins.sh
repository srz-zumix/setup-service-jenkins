#!/bin/bash

PLUGIN_FILES=$1

if [ -f "${PLUGIN_FILES}" ]; then
    echo '::group::jenkins plugin install'
    xargs -I{} jenkins-cli install-plugin {} < "${PLUGIN_FILES}"
    echo '::endgroup::'

    # get session id
    PREV_ID=$(jenkins-cli session-id)

    # restart
    jenkins-cli restart

    until jenkins-cli session-id 2>/dev/null; do
        sleep 30; echo "waiting..."
    done
    while jenkins-cli session-id | grep "${PREV_ID}"; do
        sleep 30; echo "waiting..."
    done
fi
