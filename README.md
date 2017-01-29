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
    --update-delay 10s \
    --update-parallelism 1 \
    -p 8500:8500 sdelrio/consul
```

## Environment vars

The image use the official `consul` as base image, so all environment vars can be used (like `CONSUL_LOCAL_CONFIG`, `CONSUL_BIND_INTERFACE`).

- `CONSUL`: Name of the service to ask for other consul peers. The image will use docker DNS to find the other peers. Usually this will be the name of the swarm service.
- `CONSUL_CHECK_LEADER`: If is `true` the logs will show each health check interval if the container is the leader and or container's IP and the leader's IP:

```
consul_consul.3.l0e0zr114x50@swarm-1    | 2017/01/26 00:11:22     [CP] I'm leader (172.20.0.6)
consul_consul.2.qwx39safki82@swarm-2    | 2017/01/26 00:11:26     [CP] Leader is 172.20.0.6, I'm 172.20.0.3
consul_consul.4.qws5isxw6gpm@swarm-3    | 2017/01/26 00:11:27     [CP] Leader is 172.20.0.6, I'm 172.20.0.4
consul_consul.3.l0e0zr114x50@swarm-1    | 2017/01/26 00:11:32     [CP] I'm leader (172.20.0.6)
consul_consul.2.qwx39safki82@swarm-2    | 2017/01/26 00:11:36     [CP] Leader is 172.20.0.6, I'm 172.20.0.3
consul_consul.4.qws5isxw6gpm@swarm-3    | 2017/01/26 00:11:37     [CP] Leader is 172.20.0.6, I'm 172.20.0.4
consul_consul.3.l0e0zr114x50@swarm-1    | 2017/01/26 00:11:42     [CP] I'm leader (172.20.0.6)
```

## Docker Entry Point

The entrypoint will execute consul with containerpilot, you can use the command to set your own parameters, by default the command will need 3 replicas:

```
agent -server -bootstrap-expect 3 -ui -client=0.0.0.0 -retry-interval 5s --log-level warn
```

## References

- Oficial consul image: <https://hub.docker.com/_/consul/>
- Autopilot Pattern with consul: <https://github.com/autopilotpattern/consul>

