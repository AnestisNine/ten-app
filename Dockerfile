# syntax=docker/dockerfile:1.7
# One image: the API plus the Flutter web app, served from the same origin.

ARG NODE_IMAGE=node:22-bookworm-slim
ARG DEBIAN_IMAGE=debian:bookworm-slim

# ---------------------------------------------------------------- Flutter web build
FROM ${DEBIAN_IMAGE} AS flutter
ARG FLUTTER_VERSION=3.47.7
ARG FLUTTER_SHA256=af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils python3 \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
 && tar -xf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz
ENV PATH=/opt/flutter/bin:$PATH
RUN git config --global --add safe.directory /opt/flutter \
 && flutter --disable-analytics \
 && flutter precache --web
WORKDIR /src/apps/manager
COPY apps/manager/pubspec.yaml apps/manager/pubspec.lock ./
RUN flutter pub get
COPY apps/manager/ ./
RUN python3 scripts/patch_web.py \
 && flutter build web --release --no-web-resources-cdn --pwa-strategy=none

# ---------------------------------------------------------------- API build
FROM ${NODE_IMAGE} AS api
RUN corepack enable
WORKDIR /src
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json ./
COPY packages/shared/package.json packages/shared/
COPY services/api/package.json services/api/
RUN pnpm install --frozen-lockfile --filter @tbn/api...
COPY packages/shared packages/shared
COPY services/api services/api
RUN pnpm --filter @tbn/shared build \
 && pnpm --filter @tbn/api build \
 && pnpm --filter @tbn/api deploy --prod --legacy /out \
 && rm -rf /out/src /out/tsconfig.json /out/vitest.config.ts /out/drizzle.config.ts

# ---------------------------------------------------------------- runtime
FROM ${NODE_IMAGE}
ENV NODE_ENV=production \
    PORT=8080 \
    WEB_APP_DIR=/app/web \
    FILES_DIR=/data/files
WORKDIR /app
COPY --from=api /out ./
COPY --from=flutter /src/apps/manager/build/web ./web
RUN mkdir -p /data/files && chown -R node:node /data
USER node
EXPOSE 8080
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD node -e "fetch('http://127.0.0.1:8080/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "dist/server.js"]
