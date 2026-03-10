# ==================== Builder ====================
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Download dependencies
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Build
COPY . .
ARG version=v2.0.0
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.version=${version}" \
    -o /app/portal ./cmd/portal/

# ==================== Production ====================
FROM alpine:3.19 AS production

# Security: Create non-root user
RUN addgroup -S portal && adduser -S portal -G portal

WORKDIR /app

# Copy CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy binary
COPY --from=builder --chown=portal:portal /app/portal /app/portal

# Security: Switch to non-root user
USER portal

ENTRYPOINT ["./portal", "serve", "--port"]
CMD ["1337"]
