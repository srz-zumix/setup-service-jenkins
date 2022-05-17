#!/bin/bash

if [ -n "${INSTALL_PLUGINS}" ]; then
    echo '::group::jenkins plugin install'
    echo "${INSTALL_PLUGINS}" | xargs -I{} jenkins-cli install-plugin {}
    echo '::endgroup::'
fi
