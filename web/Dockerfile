FROM node:22-alpine AS builder

RUN corepack enable

WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN npm_config_minimum_release_age=0 pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/build ./build

EXPOSE 3000
ENV PORT=3000
ENV HOST=0.0.0.0

CMD ["node", "build"]
