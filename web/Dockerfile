FROM node:22-alpine AS builder

ENV CI=true
RUN apk upgrade --no-cache && corepack enable

WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm config set minimum-release-age 0 --location global && pnpm install --frozen-lockfile

COPY . .
ARG BASE_PATH
ENV BASE_PATH=$BASE_PATH
RUN pnpm build

FROM node:22-alpine
RUN apk upgrade --no-cache && corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --prod --frozen-lockfile
COPY --from=builder /app/build ./build

EXPOSE 3000
ENV PORT=3000
ENV HOST=0.0.0.0

CMD ["node", "build"]
