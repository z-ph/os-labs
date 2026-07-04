<%@ page import="java.net.InetAddress" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String nodeName = System.getenv("NODE_NAME");
    if (nodeName == null || nodeName.trim().isEmpty()) {
        nodeName = InetAddress.getLocalHost().getHostName();
    }
%>
<!doctype html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>验收清单 - 操作系统实验课程服务门户</title>
    <style>
        body { font-family: Arial, "Microsoft YaHei", sans-serif; background: #f4f7fb; color: #1f2937; line-height: 1.65; margin: 0; }
        main { width: min(980px, calc(100% - 32px)); margin: 32px auto; background: #fff; border: 1px solid #dbe3ef; border-radius: 8px; padding: 24px; }
        h1 { color: #1f5fbf; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #dbe3ef; padding: 10px 12px; text-align: left; }
        th { background: #eef5ff; }
        .ok { color: #0f766e; font-weight: 700; }
        a { color: #1f5fbf; }
    </style>
</head>
<body>
<main>
    <h1>项目验收清单</h1>
    <p>当前处理节点：<span class="ok"><%= nodeName %></span></p>
    <table>
        <tr><th>验收项</th><th>说明</th><th>建议截图证据</th></tr>
        <tr><td>Docker 服务</td><td>Docker 正常启动并支持客户端/服务端通信</td><td>systemctl status docker、docker version</td></tr>
        <tr><td>项目镜像</td><td>基础镜像、Nginx 镜像、Tomcat 镜像构建完成</td><td>docker images</td></tr>
        <tr><td>容器拓扑</td><td>nginx-lb、tomcat1、tomcat2 均运行</td><td>docker ps、docker network inspect</td></tr>
        <tr><td>Nginx 配置</td><td>upstream web 包含两个 Tomcat 后端</td><td>nginx -t、nginx -T</td></tr>
        <tr><td>业务访问</td><td>门户首页、资源页、验收清单页可访问</td><td>浏览器或 curl 访问页面</td></tr>
        <tr><td>负载均衡</td><td>Nginx 入口访问会落到不同 Tomcat 节点</td><td>连续访问 /health.jsp</td></tr>
        <tr><td>容错恢复</td><td>停止一个后端后，入口仍可访问存活节点</td><td>docker stop/start 与访问结果</td></tr>
        <tr><td>日志维护</td><td>可通过容器日志排查后端运行状态</td><td>docker logs --tail 20</td></tr>
    </table>
    <p><a href="/">返回首页</a></p>
</main>
</body>
</html>
