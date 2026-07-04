#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [ ! -f nginx-1.15.2.tar.gz ]; then
    curl -LO http://nginx.org/download/nginx-1.15.2.tar.gz
fi

if [ ! -f apache-tomcat-9.0.68.zip ]; then
    curl -LO https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.68/bin/apache-tomcat-9.0.68.zip
fi

sudo docker pull cr.kylinos.cn/kylin/kylin-server-init:v10sp1
sudo docker tag cr.kylinos.cn/kylin/kylin-server-init:v10sp1 kylin-base:v10sp1

sudo docker build -t kylin-tomcat:861 -f tomcat/Dockerfile .
sudo docker build -t kylin-nginx:861 -f nginx/Dockerfile .

sudo docker network create kylin-lb-net 2>/dev/null || true
sudo docker rm -f nginx-lb tomcat1 tomcat2 2>/dev/null || true

sudo docker run -d --network kylin-lb-net -p 8080:8080 -e NODE_NAME=KYLIN-TOMCAT-1 --name tomcat1 kylin-tomcat:861
sudo docker run -d --network kylin-lb-net -p 8081:8080 -e NODE_NAME=KYLIN-TOMCAT-2 --name tomcat2 kylin-tomcat:861

sleep 15

sudo docker run -d --network kylin-lb-net -p 80:80 --name nginx-lb kylin-nginx:861
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
