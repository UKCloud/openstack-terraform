#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.

echo '
version: "3"

services:
  php-fpm:
    tty: true
    build: ./
    image: bobbydvo/dummyapp_php-fpm:latest
    ports:
      - "9000:9000"
    environment:
      - APPLICATION_ENV=prod
    deploy:
      mode: global
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: continue
        monitor: 60s
        max_failure_ratio: 0.3
  web:
    tty: true
    depends_on:
      - php-fpm
    image: bobbydvo/ukc_nginx:latest
    ports:
      - "80:80"
    deploy:
      mode: global
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: continue
        monitor: 60s
        max_failure_ratio: 0.3
  elasticsearch:
    tty: true
    image: bobbydvo/ukc_elasticsearch:latest
    ports:
      - "9200:9200"
    deploy:
      mode: replicated
      replicas: 1
  kibana:
    tty: true
    image: bobbydvo/ukc_kibana:latest
    ports:
      - "5601:5601"
    links:
      - "elasticsearch"
    deploy:
      mode: replicated
      replicas: 1
  logstash:
    tty: true
    image: bobbydvo/ukc_logstash:latest
    links:
      - "elasticsearch"
    deploy:
      mode: replicated
      replicas: 1
  collectd:
    tty: true
    image: bobbydvo/ukc_collectd:latest
    depends_on:
      - logstash
    deploy:
      mode: global


' > /home/core/docker-compose.yml 
chown core:core /home/core/docker-compose.yml

docker swarm init
docker swarm join-token --quiet worker > /home/core/worker-token
docker swarm join-token --quiet manager > /home/core/manager-token

docker stack deploy --compose-file /home/core/docker-compose.yml mystack > /dev/null
#docker pull bobbydvo/ukc_nginx:latest
#docker pull bobbydvo/ukc_php-fpm:latest
#docker network create --driver overlay mynet
#docker service create --update-delay 10s --replicas 1 -p 80:80 --network mynet --name web bobbydvo/ukc_nginx:latest
#docker service create --update-delay 10s --env APPLICATION_ENV=prod  --replicas 1 -p 9000:9000  --network mynet --name php-fpm bobbydvo/ukc_php-fpm:latest

#The above services should be created by the DAB bundle..
#..but Docker 1.13 is changing the work bundles & stacks work so parking for now.

