# syntax=docker/dockerfile:1.2

FROM docker.io/library/node:24.7-alpine

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

COPY ./config/.env .
COPY ./config/config.js ./app/src/config.js

EXPOSE 3000/tcp

ENV \
    JWT_KEY="please_change_me" \
    NODE_ENV="production" \
    PORT="3000" \
    HOST=""

CMD ["npm", "start"]
