# syntax=docker/dockerfile:1.2

FROM docker.io/library/node:22.19-alpine AS node

FROM node AS builder

# https://github.com/miroslavpejic85/mirotalk/commit/<commit_hash_here>
# to update the source code version, change the commit hash to the required (latest) one
ARG MIROTALK_REPO_HASH="c9f669abf2cc17c6fd64d15ce3e3090128953936"

WORKDIR /mirotalk

RUN set -x \
    && wget -O- -nv "https://github.com/miroslavpejic85/mirotalk/archive/$MIROTALK_REPO_HASH.tar.gz" \
      | tar -xz --strip-components=1 -C . \
    && find . -mindepth 1 \
      ! -path './app' ! -path './app/*' \
      ! -path './public' ! -path './public/*' \
      ! -name 'package*.json' \
      -exec rm -rf {} +

RUN set -x \
    && npm ci --only=production \
    && npm cache clean --force

# apply patches to the source code
RUN --mount=type=bind,source=patches,target=/mirotalk/patches \
    set -x \
    && apk add --no-cache patch \
    && for f in ./patches/*.patch; do patch -p1 < "$f"; done \
    && apk del patch

COPY ./config/.env.default ./.env
COPY ./config/config.js ./app/src/config.js

RUN set -x \
    && mkdir -p /tmp/rootfs/etc \
    && cd /tmp/rootfs \
    && echo 'appuser:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo 'appuser:x:10001:' > ./etc/group

FROM node AS final

LABEL \
    # Docs: <https://github.com/opencontainers/image-spec/blob/master/annotations.md>
    org.opencontainers.image.title="mirotalk" \
    org.opencontainers.image.description="A JavaScript-based project for real-time communication and collaboration" \
    org.opencontainers.image.url="https://github.com/iddqd-uk/mirotalk" \
    org.opencontainers.image.source="https://github.com/miroslavpejic85/mirotalk" \
    org.opencontainers.image.vendor="iddqd-uk" \
    org.opencontainers.image.licenses="MIT"

COPY --from=builder /tmp/rootfs /
COPY --from=builder /mirotalk /mirotalk

WORKDIR /mirotalk

ENV \
    NPM_CONFIG_UPDATE_NOTIFIER="false" \
    JWT_KEY="please_change_me" \
    API_KEY_SECRET="please_change_me_too" \
    NODE_ENV="production" \
    PORT="3000" \
    HOST=""

# use an unprivileged user
USER 10001:10001

EXPOSE 3000/tcp

CMD ["npm", "start"]
