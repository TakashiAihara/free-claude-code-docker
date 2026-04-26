# Build stage
FROM python:3.14-alpine@sha256:dd4d2bd5b53d9b25a51da13addf2be586beebd5387e289e798e4083d94ca837a AS builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    git \
    libffi-dev \
    openssl-dev \
    rust \
    cargo \
    curl

# Install uv (pinned version for reproducibility)
RUN curl -LsSf https://astral.sh/uv/0.11.7/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Set working directory
WORKDIR /app

# Copy project files
COPY pyproject.toml uv.lock ./
COPY README.md ./
COPY .env.example ./
COPY api ./api
COPY cli ./cli
COPY config ./config
COPY core ./core
COPY messaging ./messaging
COPY providers ./providers
COPY server.py ./
COPY nvidia_nim_models.json ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Runtime stage
FROM python:3.14-alpine@sha256:dd4d2bd5b53d9b25a51da13addf2be586beebd5387e289e798e4083d94ca837a

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    libffi \
    openssl

# Copy uv and virtualenv from builder
COPY --from=builder /root/.local/bin/uv /usr/local/bin/uv
COPY --from=builder /app/.venv /app/.venv

# Copy project files
WORKDIR /app
COPY --from=builder /app/pyproject.toml ./
COPY --from=builder /app/uv.lock ./
COPY --from=builder /app/README.md ./
COPY --from=builder /app/api ./api
COPY --from=builder /app/cli ./cli
COPY --from=builder /app/config ./config
COPY --from=builder /app/core ./core
COPY --from=builder /app/messaging ./messaging
COPY --from=builder /app/providers ./providers
COPY --from=builder /app/server.py ./
COPY --from=builder /app/nvidia_nim_models.json ./

# Create workspace directory
RUN mkdir -p /app/agent_workspace

# Expose port
EXPOSE 8082

# Run the server
CMD ["uv", "run", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8082"]
