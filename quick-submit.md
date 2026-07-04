# 操作系统实验与课设执行清单

本清单用于在 Kylin 系统中按阶段完成实验与课程设计验证。涉及“调整前/调整后”“正常/异常”“计数对比”的内容均拆成独立阶段，先完成当前阶段并记录结果，再进入下一阶段。

## 实验选择

建议完成以下 5 个实验，覆盖 9.1、9.2、9.4 三类内容：

1. 9.1.1 基于 Kylin OS 的进程调度与优先级实验
2. 9.2.4 内存回收实验
3. 9.4.1 多用户与权限管理
4. 9.4.2 文件快速定位与管理
5. 9.4.3 数据检索与处理

课程设计选择 9.6.1 容器化负载均衡部署实践。

## 截图原则

- 每个截图应同时包含命令和输出。
- 对比实验分别保留调整前、调整后两类结果。
- 截图可按 `9.1.1-1.png`、`9.2.4-2.png`、`9.6.1-5.png` 命名，便于整理到报告中。

## 9.4.2 文件快速定位与管理

### 阶段一：文件定位

```bash
hostname; date; whoami
find /usr -name "*pass*" | head -n 20
find /usr -name "kmod-protect.list" | head -n 5
find /dev \( -name "vd*" -o -name "sd*" \) -type b
sudo find /etc -type f -size 0 -exec ls -l {} \; | head -n 20
```

截图内容：`find /usr`、`find /dev`、`find /etc` 的输出。

### 阶段二：账号文本与日志查看

```bash
grep "nologin$" /etc/passwd
sudo tail -n 20 /var/log/messages || sudo journalctl -n 20
```

截图内容：`nologin` 账号筛选结果和系统日志末尾内容。

### 阶段三：文件类型与元数据

```bash
file /etc/passwd
stat /etc/passwd
```

截图内容：`file` 判断结果和 `stat` 元数据输出。

## 9.4.3 数据检索与处理

### 阶段一：上下文检索

```bash
hostname; date; whoami
grep -A 2 root /etc/passwd
grep -B 1 daemon /etc/passwd
grep -C 1 daemon /etc/passwd
grep --color=always -n -A 2 root /etc/passwd
```

截图内容：匹配行前后内容和带行号的匹配结果。

### 阶段二：计数结果对比

```bash
grep -c root /etc/passwd
grep root /etc/passwd | wc -l
```

截图内容：`grep -c` 与 `wc -l` 的统计结果。

### 阶段三：扩展正则表达式

```bash
mkdir -p /tmp/grep_lab
cd /tmp/grep_lab
touch file{1..10}
ls -l | grep -E 'file1{1,}'
```

截图内容：`grep -E` 对文件名的匹配结果。

### 阶段四：普通字符串与忽略大小写

```bash
cd ~
printf 'a?b\na\\?b\n' > test
cat test
egrep --color=always '\?' test
fgrep --color=always '\?' test
echo 'AaBbCc' | grep --color=always -i -E 'A|b|c'
```

截图内容：`egrep`、`fgrep` 和 `grep -i` 的输出。

## 9.4.1 多用户与权限管理

### 阶段一：创建用户和用户组

```bash
hostname; date; whoami
sudo groupadd school 2>/dev/null || true
sudo useradd -m yinhe 2>/dev/null || true
sudo useradd -m kylin 2>/dev/null || true
sudo usermod -aG school yinhe
sudo usermod -aG school kylin
```

截图内容：命令执行过程无错误即可，后续阶段会通过 `id` 验证。

### 阶段二：配置共享目录和 ACL

```bash
sudo mkdir -p /root/network
sudo chown yinhe:school /root/network
sudo chmod 3770 /root/network
sudo setfacl -m g:school:x /root
sudo setfacl -m d:g:school:rwx /root/network
sudo touch /root/network/file1
sudo chown yinhe:school /root/network/file1
sudo setfacl -m u:kylin:rw /root/network/file1
```

截图内容：目录和 ACL 配置命令执行完成。

### 阶段三：查看权限配置结果

```bash
id yinhe
id kylin
ls -ld /root /root/network
getfacl /root/network/file1
```

截图内容：`yinhe`、`kylin` 属于 `school` 组，`getfacl` 中出现 `user:kylin:rw-`。

### 阶段四：验证 sticky 位限制

```bash
sudo -u yinhe bash -c 'echo yinhe-file > /root/network/yinhe.txt'
sudo -u kylin bash -c 'rm /root/network/yinhe.txt'
ls -l /root/network
```

截图内容：`kylin` 删除 `yinhe.txt` 失败，终端出现权限不足相关提示。

## 9.1.1 进程调度与优先级

该实验需要分步观察“调整前”和“调整后”的 CPU 分配现象，使用单独分步说明：

```bash
curl -L https://raw.githubusercontent.com/z-ph/os-labs/main/exp-9.1.1-step-by-step.md | less
```

浏览器查看：

https://github.com/z-ph/os-labs/blob/main/exp-9.1.1-step-by-step.md

截图内容：

1. `gcc nice-exp.c -o nice-exp -pthread` 编译成功。
2. 两个 `nice-exp` 进程绑定到同一 CPU 核心后，调整前 `NI` 相同。
3. `sudo renice -n -5 -p $PID_A` 后，`PID_A` 的 `NI=-5`。
4. `top` 中 `NI=-5` 的进程 CPU 占用高于 `NI=0` 的进程。

## 9.2.4 内存回收实验

### 阶段一：创建并编译测试程序

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
ls -l oom
```

截图内容：`oom` 程序编译成功。

### 阶段二：记录初始内存并关闭 swap

```bash
hostname; date; whoami
sudo swapon --show
sudo swapoff -a
free -m
```

截图内容：`swapon` 与 `free -m` 的初始状态。

### 阶段三：运行程序并观察内存下降

```bash
cd ~/labs/oom_experiment
./oom &
watch -n 1 free -m
```

截图内容：`available` 内存持续下降。

### 阶段四：查看 OOM 日志并恢复 swap

```bash
dmesg | tail -n 30
sudo swapon -a
```

截图内容：内核日志中出现 `Out of memory` 或 `Killed process`。

## 9.6.1 课程设计：容器化负载均衡

### 阶段一：启动 Docker 服务

```bash
sudo yum install -y docker || sudo dnf install -y docker
sudo systemctl enable --now docker
sudo systemctl status docker
sudo docker version
```

截图内容：Docker 服务为 `active/running`，且能显示版本信息。

### 阶段二：准备基础镜像

```bash
sudo docker pull cr.kylinos.cn/kylin/kylin-server-init:v10sp1
sudo docker tag cr.kylinos.cn/kylin/kylin-server-init:v10sp1 kylin-base:v10sp1
sudo docker run --rm kylin-base:v10sp1 uname -m
sudo docker images
```

截图内容：`kylin-base:v10sp1` 存在，`uname -m` 输出 `x86_64`。

### 阶段三：构建 Nginx 镜像

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

截图内容：`kylin-nginx:861` 构建成功。

### 阶段四：构建 Tomcat 镜像

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

截图内容：`kylin-tomcat:861` 构建成功。

### 阶段五：启动并验证两个 Tomcat 后端

```bash
sudo docker network create kylin-lb-net 2>/dev/null || true
sudo docker rm -f tomcat1 tomcat2 nginx-lb 2>/dev/null || true
sudo docker run -d --network kylin-lb-net -p 8080:8080 --name tomcat1 kylin-tomcat:861
sudo docker run -d --network kylin-lb-net -p 8081:8080 --name tomcat2 kylin-tomcat:861
sleep 15
```

```bash
sudo docker exec tomcat1 bash -c 'echo KYLIN-TOMCAT-1 > /usr/local/apache-tomcat-9.0.68/webapps/ROOT/index.jsp'
sudo docker exec tomcat2 bash -c 'echo KYLIN-TOMCAT-2 > /usr/local/apache-tomcat-9.0.68/webapps/ROOT/index.jsp'
curl http://127.0.0.1:8080
curl http://127.0.0.1:8081
```

截图内容：8080 返回 `KYLIN-TOMCAT-1`，8081 返回 `KYLIN-TOMCAT-2`。

### 阶段六：配置并启动 Nginx 负载均衡

```bash
sudo docker run -itd --network kylin-lb-net -p 80:80 --name nginx-lb kylin-nginx:861
sudo docker exec -i nginx-lb tee /usr/local/nginx/conf/nginx.conf > /dev/null <<'EOF'
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
EOF
```

```bash
sudo docker exec nginx-lb /usr/local/nginx/sbin/nginx -t
sudo docker exec nginx-lb /usr/local/nginx/sbin/nginx
sudo docker ps
for i in {1..8}; do curl -s http://127.0.0.1; echo; done
```

截图内容：`nginx -t` 成功，连续访问 80 端口时出现两个 Tomcat 的不同响应。

### 阶段七：容错验证

```bash
sudo docker stop tomcat1
for i in {1..5}; do curl -s http://127.0.0.1; echo; done
```

截图内容：停止 `tomcat1` 后，服务仍可由 `tomcat2` 响应。

```bash
sudo docker start tomcat1
sudo docker ps
```

截图内容：`tomcat1` 恢复后三个容器均处于运行状态。

## 提交前自查

1. 实验报告包含 5 个实验：9.1.1、9.2.4、9.4.1、9.4.2、9.4.3。
2. 进程调度实验至少保留编译、调整前、调整后、`top` 观察四类截图。
3. 内存回收实验至少保留初始内存、内存下降、OOM 日志三类截图。
4. 课程设计至少保留 Docker 服务、镜像构建、Tomcat 后端、Nginx 轮询、容错测试截图。
5. Word 封面信息、红色待替换内容和截图位置全部处理完成后再导出提交。
