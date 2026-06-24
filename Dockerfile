ARG GLEAM_VERSION=v1.14.0

# Build stage - compile the application
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

COPY ./server /build/server
RUN cd /build/server && gleam deps download
RUN cd /build/server && gleam export erlang-shipment

# Runtime stage - slim image with only what's needed to run
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

# Copy the compiled server code from the builder stage
COPY --from=builder /build/server/build/erlang-shipment /app

# Set up the entrypoint
WORKDIR /app
RUN echo -e '#!/bin/sh\nexec ./entrypoint.sh "$@"' > ./start.sh \
  && chmod +x ./start.sh

# Create data directory for SQLite persistence
RUN mkdir -p /app/data && chmod 755 /app/data

# Set environment variables
ENV HOST=0.0.0.0
ENV PORT=1234
ENV DATABASE_PATH=/app/data/database.db

EXPOSE 1234

# Run the server
CMD ["./start.sh", "run"]