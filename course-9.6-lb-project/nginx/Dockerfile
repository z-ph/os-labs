FROM kylin-base:v10sp1

RUN yum -y install gcc make pcre-devel zlib-devel tar zlib

ADD nginx-1.15.2.tar.gz /usr/src/
RUN cd /usr/src/nginx-1.15.2 && \
    mkdir -p /usr/local/nginx && \
    ./configure --prefix=/usr/local/nginx && \
    make && make install && \
    ln -sf /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx

COPY nginx/nginx.conf /usr/local/nginx/conf/nginx.conf

EXPOSE 80
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
