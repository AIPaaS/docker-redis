FROM centos:7 
RUN groupadd -r redis && useradd -r -g redis redis
RUN yum -y install gcc libc6-dev make

ADD redis-3.2.1.tar.gz /usr/src

RUN mv /usr/src/redis-3.2.1 /usr/src/redis && \
    make -C /usr/src/redis && \
    make -C /usr/src/redis install && \
    rm -rf /usr/src/redis && \
    mkdir -p /etc/redis && \
    mkdir /data && chown redis:redis /data 

COPY redis-common.conf /etc/redis/redis-common.conf
COPY redis.conf /etc/redis/redis.conf
COPY redis_start.sh /etc/redis/redis_start.sh
RUN chmod 755 /etc/redis/redis_start.sh

WORKDIR ["/etc/redis"]

EXPOSE 6379

CMD ["/etc/redis/redis_start.sh"]
