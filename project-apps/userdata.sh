#!/bin/bash


echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

/sbin/sysctl -p

echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
echo ECS_CLUSTER=ProgrammersOnly >> /etc/ecs/ecs.config
service docker restart
start ecs

yum -y install aws-cli