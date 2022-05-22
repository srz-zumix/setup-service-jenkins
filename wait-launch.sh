#!/bin/bash

set -euo pipefail

wait() {
  local attempt_max=4
  local -i attempt_num=1
  until jenkins-log | grep "Jenkins is fully up and running" >/dev/null; do
    sleep 30; echo "waiting jenkins launch..."
    if ((attempt_num == attempt_max)); then
        jenkins-log
        exit 1
    fi
    ((attempt_num++))
  done
}

wait
echo '::group::jenkins docker log'
jenkins-log
echo '::endgroup::'
