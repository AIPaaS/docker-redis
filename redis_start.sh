#!/bin/sh

## needed parameter: ##
## single: START_MODE,REDIS_PORT,MAX_MEM,PASSWORD ##
## cluster: START_MODE,REDIS_PORT,MAX_MEM ##
## replication: START_MODE,REDIS_PORT,MAX_MEM,PASSWORD,MASTER_IP,MASTER_PORT ## 
## sentinel: START_MODE,REDIS_PORT,PASSWORD,MASTER_IP,MASTER_PORT ##

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
else if [[ ${START_MODE} = "master" ]]; then
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}
    echo "maxmemory ${MAX_MEM}" >> ${REDIS_CONF}
    echo "requirepass ${PASSWORD}" >> ${REDIS_CONF}
    echo "protected-mode no" >> ${REDIS_CONF}
    echo "appendonly yes" >> ${REDIS_CONF}
else if [[ ${START_MODE} = "replication" ]]; then
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}
    echo "maxmemory ${MAX_MEM}" >> ${REDIS_CONF}
    if [[ -z ${MASTER_IP} ]]; then
      while true; do
        master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
        if [[ -n ${master} ]]; then
          master="${master//\"}"
        else
          echo "Failed to find master."
          sleep 60
          exit 1
        fi 
        redis-cli -h ${master} INFO
        if [[ "$?" == "0" ]]; then
          break
        fi
        echo "Connecting to master failed.  Waiting..."
        sleep 10
      done
      MASTER_IP =${master}
    fi  
    echo "slaveof ${MASTER_IP} ${MASTER_PORT}" >> ${REDIS_CONF}
    echo "masterauth ${PASSWORD}" >> ${REDIS_CONF}
    echo "requirepass ${PASSWORD}" >> ${REDIS_CONF}    
    echo "protected-mode no" >> ${REDIS_CONF}
    echo "appendonly no" >> ${REDIS_CONF}
else if [[ ${START_MODE} = "sentinel" ]]; then
    #get master ip from pod
    while true; do
      master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
      if [[ -n ${master} ]]; then
        master="${master//\"}"
      else
        master=$(hostname -i)
      fi

      redis-cli -h ${master} INFO
      if [[ "$?" == "0" ]]; then
        break
      fi
      echo "Connecting to master failed.  Waiting..."
      sleep 10
    done        
    echo "sentinel monitor mymaster ${master} ${MASTER_PORT} 1" >> ${REDIS_CONF}
  
    echo "port ${REDIS_PORT}" >> ${REDIS_CONF}    
    echo "sentinel down-after-milliseconds mymaster 5000" >> ${REDIS_CONF}
    echo "sentinel failover-timeout mymaster 900000" >> ${REDIS_CONF}
    echo "sentinel auth-pass mymaster ${PASSWORD}" >> ${REDIS_CONF}
else
  echo "no need change redis config."
  
fi
fi
fi
fi
fi

echo "starting redis server ......."

doSql=true
while(true); do
  if $doSql; then 
      ## start redis server
      if [[ ${START_MODE} = "sentinel" ]]; then
        redis-sentinel ${REDIS_CONF} --protected-mode no
      else
         redis-server ${REDIS_CONF} --protected-mode no
      fi

      echo "started redis server ......."
      doSql=false
  fi 
  sleep 500s
done

