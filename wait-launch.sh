#!/bin/bash

until docker logs "$1" 2>&1 | grep "Jenkins is fully up and running" >/dev/null; do
  sleep 30; echo "waiting jenkins launch..."
done
echo '::group::jenkins docker log'
docker logs "$1" 2>&1
echo '::endgroup::'
