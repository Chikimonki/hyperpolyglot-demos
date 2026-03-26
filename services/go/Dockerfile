FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy Go files
COPY main.go ./
COPY go.mod ./

# Download dependencies (if any) and build
RUN go mod download || true
RUN go build -o gateway main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/
COPY --from=builder /app/gateway .

EXPOSE 8000
CMD ["./gateway"]
