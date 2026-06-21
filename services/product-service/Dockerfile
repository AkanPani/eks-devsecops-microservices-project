# services/product-service/Dockerfile

# ---------- Stage 1: Build Go binary ----------
FROM golang:1.23-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY . .

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o product-service .

# ---------- Stage 2: Runtime image ----------
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/product-service /app/product-service

ENV PORT=8081
ENV APP_ENV=prod
ENV SERVICE_NAME=product-service

EXPOSE 8081

USER appuser

ENTRYPOINT ["/app/product-service"]