#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.




#git clone  https://github.com/UKCloud/openstack-docker-swarm.git
#docker network create --driver overlay mynet
#docker service create --replicas 1 -p 80:80 --network mynet --name web bobbydvo/lemp_nginx:latest
#docker service create --replicas 10 -p 9000:9000 --network mynet --name php-fpm bobbydvo/lemp_php-fpm:1.0.0

#The above services should be created by the DAB bundle..
#..but Docker 1.13 is changing the work bundles & stacks work so parking for now.