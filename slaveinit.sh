#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.


sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/core/.ssh/key.pem core@${swarm_manager}:/home/core/worker-token /home/core/worker-token
sudo docker swarm join --token $(cat /home/core/worker-token) ${swarm_manager}
ssh -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null  -i /home/core/.ssh/key.pem core@${swarm_manager} "docker service scale php-fpm=${node_count}"
ssh -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null  -i /home/core/.ssh/key.pem core@${swarm_manager} "docker service scale web=${node_count}"