FROM node:20-slim AS base

WORKDIR /snailycad

# Install OpenSSL, git, and pnpm
RUN apt-get update -y && apt-get install -y openssl git && rm -rf /var/lib/apt/lists/* && npm install -g pnpm && pnpm config set httpTimeout 1200000

# Copy the rest of the source code
COPY . ./

FROM base AS deps

RUN pnpm install --frozen-lockfile

FROM deps AS build

ENV NODE_ENV="production"

# Build all packages (this will also build the API and Client)
RUN pnpm turbo run build --filter="{packages/*}"


FROM build AS api
ENV NODE_ENV="production"
WORKDIR /snailycad/apps/api
RUN pnpm run build
CMD ["pnpm", "start"]

FROM build AS client
ENV NODE_ENV="production"
ARG CORS_ORIGIN_URL
ARG NEXT_PUBLIC_CLIENT_URL
ARG NEXT_PUBLIC_PROD_ORIGIN
ARG DOMAIN
ENV CORS_ORIGIN_URL=${CORS_ORIGIN_URL}
ENV NEXT_PUBLIC_CLIENT_URL=${NEXT_PUBLIC_CLIENT_URL}
ENV NEXT_PUBLIC_PROD_ORIGIN=${NEXT_PUBLIC_PROD_ORIGIN}
ENV DOMAIN=${DOMAIN}
WORKDIR /snailycad/apps/client
RUN rm -rf /snailycad/apps/client/.next
RUN pnpm create-images-domain
RUN pnpm run build
CMD ["pnpm", "start"]