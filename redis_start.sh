#!/bin/sh

## needed parameter: ##
## single: START_MODE,REDIS_PORT,MAX_MEM,PASSWORD ##
## cluster: START_MODE,REDIS_PORT,MAX_MEM ##
## slave: START_MODE,REDIS_PORT,MAX_MEM,PASSWORD,MASTER_IP,MASTER_PORT ## 

REDIS_CONF="/etc/redis/redis.conf"

echo "modify redis server config......"

## modify redis.conf 
if [[ ${START_MODE} = "single" ]]; then
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}
    echo "maxmemory ${MAX_MEM}" >> ${REDIS_CONF}
    echo "requirepass ${PASSWORD}" >> ${REDIS_CONF}
    echo "protected-mode no" >> ${REDIS_CONF}
    echo "appendonly no" >> ${REDIS_CONF}
else if [[ ${START_MODE} = "cluster" ]] ; then
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}
    echo "maxmemory ${MAX_MEM}" >> ${REDIS_CONF}
    echo "cluster-config-file nodes.conf" >> ${REDIS_CONF}
    echo "cluster-node-timeout 5000" >> ${REDIS_CONF}
    echo "cluster-enabled yes" >> ${REDIS_CONF}
    echo "protected-mode no" >> ${REDIS_CONF}
    echo "appendonly yes" >> ${REDIS_CONF}
else if [[ ${START_MODE} = "slave" ]]; then
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}
    echo "maxmemory ${MAX_MEM}" >> ${REDIS_CONF}
    echo "requirepass ${PASSWORD}" >> ${REDIS_CONF}
    echo "slaveof ${MASTER_IP} ${MASTER_PORT}" >> ${REDIS_CONF}
    echo "masterauth ${PASSWORD}" >> ${REDIS_CONF}
    echo "protected-mode no" >> ${REDIS_CONF}
    echo "appendonly no" >> ${REDIS_CONF}
else
  echo "no need change redis config."
fi
fi
fi

echo "starting redis server ......."

doSql=true
while(true); do
  if $doSql; then 
      ## start redis server
      nohup redis-server ${REDIS_CONF} &
      echo "started redis server ......."
      doSql=false
  fi 
  sleep 500s
done

