#!/usr/bin/env bash
set -euo pipefail

sudo docker rm -f nginx-lb tomcat1 tomcat2 2>/dev/null || true
sudo docker network rm kylin-lb-net 2>/dev/null || true
