#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.

sudo APPLICATION_ENV=${application_env} /usr/bin/supervisord -n -c /etc/supervisord.conf