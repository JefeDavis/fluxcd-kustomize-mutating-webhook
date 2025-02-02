# Build Stage
FROM golang:1.23 AS builder

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Copy module files first to leverage Docker caching
COPY go.mod go.sum ./
RUN go mod download

# Copy entire source
COPY . .

# Build the application targeting cmd/webhook/main.go
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} \
  go build -trimpath -ldflags "-s -w" -o webhook ./cmd/webhook/main.go

# Deploy Stage
FROM gcr.io/distroless/static:nonroot

WORKDIR /
VOLUME [ "/etc/config" ]

# Copy the compiled binary from the builder stage
COPY --from=builder /app/webhook /webhook

# Set the entrypoint
ENTRYPOINT ["/webhook"]
