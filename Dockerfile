# STAGE: build
FROM envoyproxy/envoy-build-ubuntu:86873047235e9b8232df989a5999b9bebf9db69c@sha256:1b3c82ca34c505c4951918b2e0a0c3db88cf266ebbf4196e4b0fba8fa137ada3 AS build
WORKDIR /source
# COPY /home/cybercyst/.cache/envoy-bazel /root/.cache/envoy-bazel
COPY . .
ENV ENVOY_DOCKER_BUILD_DIR=/build
RUN ls -Rall && \
  ./ci/do_ci.sh release.server_only && \
  # ./ci/do_ci.sh distribution && \
  ls -Rall ${ENVOY_DOCKER_BUILD_DIR}

# STAGE: binary
FROM scratch AS binary
# COPY distribution/docker/docker-entrypoint.sh /
COPY configs/envoyproxy_io_proxy.yaml /etc/envoy/envoy.yaml
# See https://github.com/docker/buildx/issues/510 for why this _must_ be this way
ARG TARGETPLATFORM
ENV TARGETPLATFORM="${TARGETPLATFORM:-linux/amd64}"
COPY --from=build "${TARGETPLATFORM}/release.tar.zst" /usr/local/bin/

# STAGE: envoy-distroless
FROM gcr.io/distroless/base-nossl-debian12:nonroot@sha256:a1922debbf4ff2cc245d7c0d1e2021cfcee35fe24afae7505aeec59f7e7802f6 AS envoy-distroless
EXPOSE 10000
ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
COPY --from=binary --chown=0:0 --chmod=755 \
  /etc/envoy /etc/envoy
COPY --from=binary --chown=0:0 --chmod=644 \
  /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml
COPY --from=binary --chown=0:0 --chmod=755 \
  /usr/local/bin/envoy /usr/local/bin/
