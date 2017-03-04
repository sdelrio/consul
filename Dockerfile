FROM consul

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VERSION 2.6.0
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=c1bcd137fadd26ca2998eec192d04c08f62beb1f \
    && export archive=containerpilot-${CONTAINERPILOT_VERSION}.tar.gz \
    && curl -Lso /tmp/${archive} \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/${archive}" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/${archive}" | sha1sum -c \
    && tar zxf /tmp/${archive} -C /usr/local/bin \
    && rm /tmp/${archive} \
    && apk add --no-cache bash curl \
    && curl -sL https://github.com/sequenceiq/docker-alpine-dig/releases/download/v9.10.2/dig.tgz|tar -xzv -C /usr/local/bin/

# configuration files and bootstrap scripts
COPY etc/containerpilot.json etc/
COPY bin/* /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=20s --retries=10 CMD curl --fail http://localhost:8500/ui || exit 1

ENTRYPOINT ["/usr/local/bin/containerpilot", "/usr/local/bin/docker-entrypoint.sh" ]
CMD ["agent", "-server", "-bootstrap-expect", "3", "-ui", "-client=0.0.0.0", "-retry-interval", "5s", "--log-level", "warn"]

