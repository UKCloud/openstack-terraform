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
      mode: replicated
      replicas: 1
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
      mode: replicated
      replicas: 1
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: continue
        monitor: 60s
        max_failure_ratio: 0.3
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

