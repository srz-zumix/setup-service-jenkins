#!/bin/bash

if [ -n "${INSTALL_PLUGINS}" ]; then
    echo '::group::jenkins plugin install'
    for plugin in ${INSTALL_PLUGINS}; do
        jenkins-cli install-plugin "${plugin}"
    done
    echo '::endgroup::'
fi
