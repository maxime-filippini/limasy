ARG GLEAM_VERSION=v1.14.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

RUN apk add --no-cache gcc g++ make musl-dev build-base

WORKDIR /build/server

COPY ./gleam.toml ./manifest.toml ./
RUN gleam deps download

COPY . .
RUN gleam export erlang-shipment

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

RUN apk add --no-cache sqlite

COPY --from=builder /build/server/build/erlang-shipment /app

WORKDIR /app
RUN echo -e '#!/bin/sh\nexec ./entrypoint.sh "$@"' > ./start.sh \
  && chmod +x ./start.sh

RUN mkdir -p /app/data && chmod 755 /app/data

ENV HOST=0.0.0.0
ENV PORT=1234
ENV DATABASE_PATH=/app/data/database.db

EXPOSE 1234

CMD ["./start.sh", "run"]
