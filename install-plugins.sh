#!/bin/bash

PLUGIN_FILES=$1

if [ -f "${PLUGIN_FILES}" ]; then
    echo '::group::jenkins plugin install'
    xargs -I{} jenkins-cli install-plugin {} < "${PLUGIN_FILES}"
    echo '::endgroup::'
fi
