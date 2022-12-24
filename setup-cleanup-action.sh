#!/bin/bash

set -euo pipefail

mkdir -p "${GITHUB_WORKSPACE}/.github/setup-service-jenkins"
(cd "${GITHUB_WORKSPACE}/.github/setup-service-jenkins" && ln -snf "${GITHUB_ACTION_PATH}/resources/post-action" post-action)
