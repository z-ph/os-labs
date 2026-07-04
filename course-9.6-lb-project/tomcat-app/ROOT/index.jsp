<%@ page import="java.net.InetAddress" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String nodeName = System.getenv("NODE_NAME");
    if (nodeName == null || nodeName.trim().isEmpty()) {
        nodeName = InetAddress.getLocalHost().getHostName();
    }
    String appVersion = "course-portal-v1.0";
    String hostName = InetAddress.getLocalHost().getHostName();
%>
<!doctype html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>操作系统实验课程服务门户</title>
    <style>
        body { margin: 0; font-family: Arial, "Microsoft YaHei", sans-serif; background: #f4f7fb; color: #1f2937; line-height: 1.65; }
        header { background: #183b73; color: #fff; padding: 30px 0; }
        .wrap { width: min(1080px, calc(100% - 32px)); margin: 0 auto; }
        h1 { margin: 0 0 8px; font-size: 30px; }
        header p { margin: 0; color: #dbeafe; }
        nav { background: #fff; border-bottom: 1px solid #d7e0ec; }
        nav .wrap { display: flex; gap: 18px; padding: 12px 0; flex-wrap: wrap; }
        nav a { color: #1f5fbf; text-decoration: none; font-weight: 700; }
        main { padding: 26px 0 44px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }
        .card { background: #fff; border: 1px solid #dbe3ef; border-radius: 8px; padding: 18px; }
        .card h2 { margin: 0 0 10px; font-size: 20px; color: #1f5fbf; }
        .node { font-size: 24px; font-weight: 700; color: #0f766e; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; background: #fff; }
        th, td { border: 1px solid #dbe3ef; padding: 10px 12px; text-align: left; }
        th { background: #eef5ff; color: #183b73; }
        .ok { color: #0f766e; font-weight: 700; }
        .muted { color: #64748b; }
    </style>
</head>
<body>
<header>
    <div class="wrap">
        <h1>操作系统实验课程服务门户</h1>
        <p>面向 Kylin OS 实验与课程设计的资料发布、验收清单和服务状态展示系统。</p>
    </div>
</header>
<nav>
    <div class="wrap">
        <a href="/">首页</a>
        <a href="/resources.jsp">实验资料</a>
        <a href="/checklist.jsp">验收清单</a>
        <a href="/health.jsp">健康检查</a>
        <a href="/api/status.jsp">状态 API</a>
    </div>
</nav>
<main>
    <div class="wrap">
        <div class="grid">
            <section class="card">
                <h2>当前服务节点</h2>
                <div class="node"><%= nodeName %></div>
                <p class="muted">通过 Nginx 入口连续刷新或 curl 访问时，应能在两个 Tomcat 节点之间切换。</p>
            </section>
            <section class="card">
                <h2>服务状态</h2>
                <p class="ok">UP</p>
                <p>应用版本：<%= appVersion %></p>
                <p>容器主机名：<%= hostName %></p>
            </section>
            <section class="card">
                <h2>项目用途</h2>
                <p>为操作系统实验课程提供统一入口，便于查看实验资料、确认提交材料、验证负载均衡节点和检查服务状态。</p>
            </section>
        </div>

        <h2>课程模块</h2>
        <table>
            <tr><th>模块</th><th>用途</th><th>验收证据</th></tr>
            <tr><td>实验资料</td><td>集中列出实验与课设材料</td><td>访问 /resources.jsp</td></tr>
            <tr><td>验收清单</td><td>检查报告、截图和项目证据</td><td>访问 /checklist.jsp</td></tr>
            <tr><td>健康检查</td><td>供 Nginx/运维验证后端状态</td><td>访问 /health.jsp</td></tr>
            <tr><td>状态 API</td><td>输出节点、版本和服务角色</td><td>访问 /api/status.jsp</td></tr>
        </table>
    </div>
</main>
</body>
</html>
