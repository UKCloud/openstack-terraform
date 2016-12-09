#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.


#git clone  https://github.com/UKCloud/openstack-docker-swarm.git
#docker service create --replicas 1 -p 80:80 --name web nginx:alpine
#docker service create --replicas 10 -p 9000:9000 --name php-fpm php:7.0.8-fpm-alpine

#The above services should be created by the DAB bundle..
#..but Docker 1.13 is changing the work bundles & stacks work so parking for now.