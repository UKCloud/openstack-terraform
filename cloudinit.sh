#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.



sudo chown -R centos:centos ${clone_location}
git clone ${git_repo} ${clone_location}
cd ${clone_location}

export COMPOSER_HOME=${clone_location}
composer install

sudo APPLICATION_ENV=${application_env} /usr/bin/supervisord -n -c /etc/supervisord.conf