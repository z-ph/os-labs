# 9.6.1 容器化负载均衡课程设计项目

本目录是课程设计 9.6.1 的完整项目源码与部署材料。项目应用为“操作系统实验课程服务门户”，用于集中展示实验资料、验收清单、课程设计运行状态和服务健康信息。报告中不需要粘贴源码，只需要说明项目结构、部署流程、测试结果和截图证据。

## 项目结构

```text
course-9.6-lb-project/
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
├── tomcat/
│   └── Dockerfile
├── tomcat-app/
│   └── ROOT/
│       ├── index.jsp
│       ├── resources.jsp
│       ├── checklist.jsp
│       ├── health.jsp
│       ├── api/status.jsp
│       └── WEB-INF/web.xml
└── scripts/
    ├── deploy.sh
    ├── verify.sh
    └── clean.sh
```

## 项目功能

- 使用 `kylin-base:v10sp1` 作为基础镜像。
- 构建 `kylin-tomcat:861` 镜像，内置操作系统实验课程服务门户。
- 构建 `kylin-nginx:861` 镜像，内置 Nginx upstream 负载均衡配置。
- 启动 `tomcat1`、`tomcat2`、`nginx-lb` 三个容器。
- 使用 `kylin-lb-net` Docker 自定义网络实现容器名解析。
- 将宿主机 `8080/8081` 映射到两个 Tomcat 后端，将宿主机 `80` 映射到 Nginx 入口。
- 提供课程首页、实验资源页、验收清单页、健康检查接口和状态 API。
- 通过访问页面、健康检查、容器状态、网络拓扑、Nginx 配置和日志完成项目级验收。

## 应用入口

- `/`：课程服务门户首页，展示课程模块、当前服务节点和运行状态。
- `/resources.jsp`：实验与课程设计资料索引，便于在 Kylin 环境中查看材料清单。
- `/checklist.jsp`：实验与课程设计验收清单，用于对照准备截图和报告内容。
- `/health.jsp`：JSON 健康检查接口，用于负载均衡与容器健康验证。
- `/api/status.jsp`：JSON 状态接口，用于查看应用版本、节点名称和服务角色。

## 在 Kylin 中执行

```bash
cd ~
git clone https://github.com/z-ph/os-labs.git 2>/dev/null || (cd os-labs && git pull)
cd ~/os-labs/course-9.6-lb-project
bash scripts/deploy.sh
bash scripts/verify.sh
```

## 清理项目

```bash
cd ~/os-labs/course-9.6-lb-project
bash scripts/clean.sh
```
