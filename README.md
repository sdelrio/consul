# Consul with the Autopilot Pattern

[Consul](http://www.consul.io/) in Docker, designed to be self-operating according to the autopilot pattern. This application demonstrates support for configuring the Consul raft so it can be used as a highly-available discovery catalog for other applications using the Autopilot pattern.

[![DockerPulls](https://img.shields.io/docker/pulls/sdelrio/consul.svg)](https://registry.hub.docker.com/u/sdelrio/consul/)
[![DockerStars](https://img.shields.io/docker/stars/sdelrio/consul.svg)](https://registry.hub.docker.com/u/sdelrio/consul/)
[![ImageLayers](https://badge.imagelayers.io/sdelrio/consul:latest.svg)](https://imagelayers.io/?images=sdelrio/consul:latest)


## Run consul in a virtualbox swarm cluster

1. If you don't have it, install the Docker for Windows, docker for Mac, or Docker Toolbox(including `docker` and `docker-compose`) on your laptop or other environment.
1. Create a swarm mode cluster

The option `--engine-opt experimental` is not mandatory but on docker v1.13 you can run `docker service logs consul`, to view the logs from all the cluster service.

```
for i in 1 2 3; do
    docker-machine create -d virtualbox --engine-opt experimental swarm-$i
done

eval $(docker-machine env swarm-1)

docker swarm init --advertise-addr $(docker-machine ip swarm-1)

TOKEN=$(docker swarm join-token -q manager)

for i in 2 3; do
  eval $(docker-machine env swarm-$i)
  docker swarm join --token $TOKEN --advertise-addr $(docker-machine ip swarm-$i) $(docker-machine ip swarm-1):2377
done

```

1. Create a network for consul

```
docker network create consul-net -d overlay --subnet=172.20.0.0/24
```
The option `--subnet` is not mandatory, is just I want to be on different network that the usually 10.x.x.x that docker assign by default.

1. Create a service for the swarm

1.1 Using `docker-compose` v1.10+

```
docker deploy -c docker-compose.yml consul
```

1.2 Manually creating the service

```
docker service create --network=consul-net --name=consul \
    -e 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}' \
    -e CONSUL_BIND_INTERFACE='eth0' \
    -e CONSUL=consul \
    -e CONSUL_CHECK_LEADER=true \
    --replicas 3 \
    -update-delay 10s \
    -update-parallelism 1 \
    -p 8500:8500 sdelrio/consul
```

## References

- Oficial consul image: <https://hub.docker.com/_/consul/>
- Autopilot Pattern with consul: <https://github.com/autopilotpattern/consul>

