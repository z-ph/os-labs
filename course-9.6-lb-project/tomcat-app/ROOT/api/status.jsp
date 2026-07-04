<%@ page import="java.net.InetAddress" %>
<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String nodeName = System.getenv("NODE_NAME");
    if (nodeName == null || nodeName.trim().isEmpty()) {
        nodeName = InetAddress.getLocalHost().getHostName();
    }
%>
{
  "service": "os-course-portal",
  "version": "course-portal-v1.0",
  "role": "tomcat-backend",
  "node": "<%= nodeName %>",
  "host": "<%= InetAddress.getLocalHost().getHostName() %>"
}
