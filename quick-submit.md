# 明天提交速查清单

## 总路线

优良最快路径：

1. 9.4.2 文件快速定位与管理，10-15 分钟。
2. 9.4.3 数据检索与处理，10-15 分钟。
3. 9.4.1 多用户与权限管理，15-20 分钟。
4. 9.1.1 基于 Kylin OS 的进程调度与优先级实验，20-30 分钟。
5. 9.2.4 内存回收实验，15-25 分钟。
6. 课程设计选 9.6.1 容器化负载均衡部署实践。

前 4 个小实验用于保良，第 5 个小实验用于冲优。它们覆盖 9.1、9.2、9.4 三个不同大类，满足“至少 3 个且属于不同大类”的基本要求。

报告骨架已经生成：

- `C:\Users\30513\Desktop\操作系统实验报告-快速完成骨架.docx`
- `C:\Users\30513\Desktop\操作系统课程设计报告-9.6容器化负载均衡骨架.docx`

提交前只需要：

1. 填封面：学院、班级、学号、姓名、日期。
2. 按下面顺序执行命令。
3. 把截图贴到 Word 里对应的黄色“截图占位”处。
4. 系统测试表里的“实际结果”改成“通过”或贴自己的输出。

## 截图原则

每个实验截图不求多，关键是能证明你做过：

- 命令和输出要在同一张图里。
- 终端里最好先执行 `hostname; date; whoami`，让截图更像自己的环境。
- 截图文件可以命名为 `9.4.2-1.png`、`9.1.1-3.png` 这种，方便贴图。

## 9.4.2 文件快速定位与管理

复制执行：

```bash
hostname; date; whoami
find /usr -name "*pass*" | head -n 20
find /dev \( -name "vd*" -o -name "sd*" \) -type b
sudo find /etc -type f -size 0 -exec ls -l {} \; | head -n 20
grep "nologin$" /etc/passwd
sudo tail -n 20 /var/log/messages || sudo journalctl -n 20
file /etc/passwd
stat /etc/passwd
```

截图：

1. `find /usr`、`find /dev`、`find /etc` 的输出。
2. `grep "nologin$"` 和日志输出。
3. `file /etc/passwd`、`stat /etc/passwd` 输出。

贴到实验报告第 4 个实验的“7、程序运行结果”。

## 9.4.3 数据检索与处理

复制执行：

```bash
hostname; date; whoami
grep -A 2 root /etc/passwd
grep -B 1 daemon /etc/passwd
grep -C 1 daemon /etc/passwd
grep --color=always -n -A 2 root /etc/passwd
grep -c root /etc/passwd
grep root /etc/passwd | wc -l

mkdir -p /tmp/grep_lab
cd /tmp/grep_lab
touch file{1..10}
ls -l | grep -E 'file1{1,}'

cd ~
printf 'a?b\na\\?b\n' > test
cat test
egrep --color=always '\?' test
fgrep --color=always '\?' test
echo 'AaBbCc' | grep --color=always -i -E 'A|b|c'
```

截图：

1. `grep -A/-B/-C` 和 `-n` 输出。
2. `grep -c` 与 `wc -l` 计数输出。
3. `grep -E`、`egrep`、`fgrep`、`-i` 输出。

贴到实验报告第 5 个实验的“7、程序运行结果”。

## 9.4.1 多用户与权限管理

复制执行：

```bash
hostname; date; whoami
sudo groupadd school 2>/dev/null || true
sudo useradd -m yinhe 2>/dev/null || true
sudo useradd -m kylin 2>/dev/null || true
sudo usermod -aG school yinhe
sudo usermod -aG school kylin

sudo mkdir -p /root/network
sudo chown yinhe:school /root/network
sudo chmod 3770 /root/network
sudo setfacl -m g:school:x /root
sudo setfacl -m d:g:school:rwx /root/network

sudo touch /root/network/file1
sudo chown yinhe:school /root/network/file1
sudo setfacl -m u:kylin:rw /root/network/file1

id yinhe
id kylin
ls -ld /root /root/network
getfacl /root/network/file1

sudo -u yinhe bash -c 'echo yinhe-file > /root/network/yinhe.txt'
sudo -u kylin bash -c 'rm /root/network/yinhe.txt'
ls -l /root/network
```

截图：

1. `id yinhe`、`id kylin`、`ls -ld /root /root/network`。
2. `getfacl /root/network/file1` 中有 `user:kylin:rw-`。
3. kylin 删除 yinhe 文件失败，出现 `Operation not permitted`。

贴到实验报告第 3 个实验的“7、程序运行结果”。

## 9.1.1 进程调度与优先级

这个实验不要一次性粘贴所有命令。请打开单独的分步版，按步骤确认现象后再继续：

```bash
curl -L https://raw.githubusercontent.com/z-ph/os-labs/main/exp-9.1.1-step-by-step.md | less
```

浏览器链接：

https://github.com/z-ph/os-labs/blob/main/exp-9.1.1-step-by-step.md

截图放入实验报告第 1 个实验的“7、程序运行结果”：

1. 编译成功和 `nice-exp` 文件。
2. 两个进程绑定在同一个 CPU 核心上竞争。
3. `renice` 后 `NI` 值变化，`top` 中 CPU 占比出现差异。

## 9.2.4 内存回收实验

只在虚拟机做，做之前保存其它东西。

复制执行：

```bash
mkdir -p ~/labs/oom_experiment
cd ~/labs/oom_experiment
cat > oom.c <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define STEP_SIZE (4 * 1024 * 1024)

int main(void)
{
    long count = 0;
    for (;;) {
        char *memory = (char *)malloc(STEP_SIZE);
        if (!memory) {
            perror("malloc");
            sleep(1);
            continue;
        }
        memset(memory, 0, STEP_SIZE);
        count++;
        if (count % 25 == 0) {
            printf("allocated about %ld MB\n", count * 4);
            fflush(stdout);
        }
        usleep(10000);
    }
    return 0;
}
EOF
gcc oom.c -o oom
```

复制执行：

```bash
hostname; date; whoami
sudo swapon --show
sudo swapoff -a
free -m
./oom &
watch -n 1 free -m
```

看到 `available` 明显下降后截图。进程被杀后按 `Ctrl+C` 退出 watch，再执行：

```bash
dmesg | tail -n 30
sudo swapon -a
```

截图：

1. `swapon/free` 输出。
2. `watch free -m` 中内存下降。
3. `dmesg` 有 `Out of memory: Killed process`。

贴到实验报告第 2 个实验的“7、程序运行结果”。

## 9.6.1 课程设计：容器化负载均衡

### 1. Docker 服务

```bash
sudo yum install -y docker || sudo dnf install -y docker
sudo systemctl enable --now docker
sudo systemctl status docker
sudo docker version
```

截图：Docker active/running 和 version。

### 2. 基础镜像

```bash
sudo docker pull cr.kylinos.cn/kylin/kylin-server-init:v10sp1
sudo docker tag cr.kylinos.cn/kylin/kylin-server-init:v10sp1 kylin-base:v10sp1
sudo docker run --rm kylin-base:v10sp1 uname -m
sudo docker images
```

截图：`kylin-base:v10sp1` 存在，`uname -m` 输出 `x86_64`。

### 3. Nginx 镜像

```bash
mkdir -p ~/kylin861/nginx
cd ~/kylin861/nginx
curl -LO http://nginx.org/download/nginx-1.15.2.tar.gz
cat > Dockerfile <<'EOF'
FROM kylin-base:v10sp1
RUN yum -y install gcc make pcre-devel zlib-devel tar zlib
ADD nginx-1.15.2.tar.gz /usr/src/
RUN cd /usr/src/nginx-1.15.2 && \
    mkdir -p /usr/local/nginx && \
    ./configure --prefix=/usr/local/nginx && \
    make && make install && \
    ln -sf /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx
CMD ["/bin/bash"]
EOF
sudo docker build -t kylin-nginx:861 .
sudo docker images | grep kylin-nginx
```

截图：构建成功。

### 4. Tomcat 镜像

```bash
mkdir -p ~/kylin861/tomcat
cd ~/kylin861/tomcat
curl -LO https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.68/bin/apache-tomcat-9.0.68.zip
cat > Dockerfile <<'EOF'
FROM kylin-base:v10sp1
ADD apache-tomcat-9.0.68.zip /usr/local/
RUN yum -y install zip unzip java-1.8.0-openjdk
RUN unzip -q /usr/local/apache-tomcat-9.0.68.zip -d /usr/local/
ENV JAVA_HOME=/usr/lib/jvm/jre
ENV CATALINA_HOME=/usr/local/apache-tomcat-9.0.68
ENV PATH=$PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin
RUN chmod +x /usr/local/apache-tomcat-9.0.68/bin/catalina.sh
CMD ["/usr/local/apache-tomcat-9.0.68/bin/catalina.sh","run"]
EOF
sudo docker build -t kylin-tomcat:861 .
sudo docker images | grep kylin-tomcat
```

截图：构建成功。

### 5. 启动 Tomcat 后端

```bash
sudo docker network create kylin-lb-net 2>/dev/null || true
sudo docker rm -f tomcat1 tomcat2 nginx-lb 2>/dev/null || true

sudo docker run -d --network kylin-lb-net -p 8080:8080 --name tomcat1 kylin-tomcat:861
sudo docker run -d --network kylin-lb-net -p 8081:8080 --name tomcat2 kylin-tomcat:861
sleep 15
sudo docker exec tomcat1 bash -c 'echo KYLIN-TOMCAT-1 > /usr/local/apache-tomcat-9.0.68/webapps/ROOT/index.jsp'
sudo docker exec tomcat2 bash -c 'echo KYLIN-TOMCAT-2 > /usr/local/apache-tomcat-9.0.68/webapps/ROOT/index.jsp'

curl http://127.0.0.1:8080
curl http://127.0.0.1:8081
```

截图：8080 返回 `KYLIN-TOMCAT-1`，8081 返回 `KYLIN-TOMCAT-2`。

### 6. 启动 Nginx 负载均衡

```bash
sudo docker run -itd --network kylin-lb-net -p 80:80 --name nginx-lb kylin-nginx:861
sudo docker exec -i nginx-lb bash <<'EOF'
cat > /usr/local/nginx/conf/nginx.conf <<'NGINX'
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    upstream web {
        server tomcat1:8080;
        server tomcat2:8080;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://web;
        }
    }
}
NGINX
/usr/local/nginx/sbin/nginx -t
/usr/local/nginx/sbin/nginx
EOF

sudo docker ps
for i in {1..8}; do curl -s http://127.0.0.1; echo; done
```

截图：

1. `nginx -t` 成功，`docker ps` 有三个容器。
2. 连续 curl 后出现 `KYLIN-TOMCAT-1` 和 `KYLIN-TOMCAT-2`。

### 7. 容错测试

```bash
sudo docker stop tomcat1
for i in {1..5}; do curl -s http://127.0.0.1; echo; done
sudo docker start tomcat1
sudo docker ps
```

截图：停止 tomcat1 后仍能访问 tomcat2，恢复后三个容器都运行。

## 最后 30 分钟提交检查

1. 两份 Word 封面信息填好。
2. 实验报告至少有 4 个实验截图，最好 5 个都贴。
3. 课程设计报告 9.6 至少贴 Docker、镜像、Tomcat、Nginx 轮询、容错测试截图。
4. 模板最后“此页只是提交要求”不要保留；当前骨架已删除。
5. 文件名建议：
   - `学号-姓名-操作系统实验报告.docx`
   - `学号-姓名-操作系统课程设计报告.docx`
