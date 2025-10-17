# STAGE: build
FROM envoyproxy/envoy-build-ubuntu:f4a881a1205e8e6db1a57162faf3df7aed88eae8@sha256:b10346fe2eee41733dbab0e02322c47a538bf3938d093a5daebad9699860b814 AS build
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
