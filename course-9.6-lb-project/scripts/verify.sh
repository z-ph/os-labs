#!/usr/bin/env bash
set -euo pipefail

sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'kylin-base|kylin-nginx|kylin-tomcat'
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
sudo docker network inspect kylin-lb-net --format '{{range $id,$c := .Containers}}{{$c.Name}} {{end}}'
sudo docker inspect nginx-lb --format 'Name={{.Name}} Image={{.Config.Image}} Ports={{json .NetworkSettings.Ports}}'
sudo docker exec nginx-lb /usr/local/nginx/sbin/nginx -t
sudo docker exec nginx-lb /usr/local/nginx/sbin/nginx -T | grep -E 'upstream|server tomcat|proxy_pass'

curl -s http://127.0.0.1/ | grep '操作系统实验课程服务门户'
curl -s http://127.0.0.1/resources.jsp | grep '实验资料索引'
curl -s http://127.0.0.1/checklist.jsp | grep '项目验收清单'
curl -s http://127.0.0.1/api/status.jsp; echo
curl -s http://127.0.0.1:8080/health.jsp; echo
curl -s http://127.0.0.1:8081/health.jsp; echo
for i in {1..8}; do curl -s http://127.0.0.1/health.jsp; echo; done

sudo docker logs --tail 20 tomcat1
sudo docker logs --tail 20 tomcat2
