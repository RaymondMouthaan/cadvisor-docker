# cadvisor-docker

cAdvisor exposes container statistics as Prometheus metrics out of the box.
For more info https://github.com/google/cadvisor

This repo adds support for archetectures **arm**, **arm64** and **amd64** and can be used in a mixed architecture docker swarm cluster.


Example Docker Stack:

```
################################################################################
# Prometheus
################################################################################
#$ docker stack deploy prometheus --compose-file docker-compose-prometheus_v2.yml
################################################################################
version: "3.7"

services:
  cadvisor:
      image: raymondmm/cadvisor
      volumes:
        - /:/rootfs:ro
        - /var/run:/var/run:rw
        - /sys:/sys:ro
        - /sys/fs/cgroup:/sys/fs/cgroup:ro
        - /var/lib/docker/:/var/lib/docker:ro
        - /dev/disk/:/dev/disk:ro
      ports:
        - 8080:8080
      networks:
        - prometheus-net
      deploy:
        mode: global
        restart_policy:
          condition: on-failure
          
 networks:
  prometheus-net:
    external: false
```
