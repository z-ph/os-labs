FROM kylin-base:v10sp1

ADD apache-tomcat-9.0.68.zip /usr/local/
RUN yum -y install zip unzip java-1.8.0-openjdk && \
    unzip -q /usr/local/apache-tomcat-9.0.68.zip -d /usr/local/ && \
    chmod +x /usr/local/apache-tomcat-9.0.68/bin/catalina.sh && \
    rm -rf /usr/local/apache-tomcat-9.0.68/webapps/ROOT/*

ENV JAVA_HOME=/usr/lib/jvm/jre
ENV CATALINA_HOME=/usr/local/apache-tomcat-9.0.68
ENV PATH=$PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin

COPY tomcat-app/ROOT/ /usr/local/apache-tomcat-9.0.68/webapps/ROOT/

EXPOSE 8080
CMD ["/usr/local/apache-tomcat-9.0.68/bin/catalina.sh", "run"]
