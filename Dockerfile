# Builder
ARG ARCH
FROM ${ARCH}/golang:1.11-alpine  as builder

# Define ARGs again to make them available after FROM
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG OS
ARG ARCH
ARG QEMU_ARCH
ARG CADVISOR_VERSION

ENV CADVISOR_VERSION=${CADVISOR_VERSION}

COPY tmp/qemu-${QEMU_ARCH}-static /usr/bin/qemu-${QEMU_ARCH}-static

RUN apt-get update && apt-get install -y git dmsetup && apt-get clean

#RUN git clone --branch ${CADVISOR_VERSION} https://github.com/google/cadvisor.git /go/src/github.com/google/cadvisor
RUN mkdir -p /go/src/github.com/google/cadvisor
RUN curl -L https://github.com/google/cadvisor/archive/${CADVISOR_VERSION}.tar.gz | tar -xzf - --strip-components=1 -C /go/src/github.com/google/cadvisor

WORKDIR /go/src/github.com/google/cadvisor

RUN make build

FROM ${ARCH}/alpine:3.9
MAINTAINER dengnan@google.com vmarmol@google.com vishnuk@google.com jimmidyson@gmail.com stclair@google.com

ARG QEMU_ARCH

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="Dockerfile" \
    org.label-schema.license="GNU" \
    org.label-schema.name="cadvisor" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers." \
    org.label-schema.url="https://github.com/google/cadvisor" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/RaymondMouthaan/cadvisor-docker" \
    maintainer="Raymond M Mouthaan <raymondmmouthaan@gmail.com>"

# Copy ARCHs to ENVs to make them available at runtime
ENV OS=$OS
ENV ARCH=$ARCH
ENV CADVISOR_VERSION=${CADVISOR_VERSION}

COPY tmp/qemu-${QEMU_ARCH}-static /usr/bin/qemu-${QEMU_ARCH}-static

RUN apk --no-cache add libc6-compat device-mapper findutils zfs curl && \
    apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -rf /var/cache/apk/*

# Grab cadvisor from the staging directory.
COPY --from=builder /go/src/github.com/google/cadvisor/cadvisor /usr/bin/cadvisor

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
