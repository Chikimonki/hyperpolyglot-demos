FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod ./
COPY coordinator.go ./
RUN go mod download
RUN go build -o coordinator coordinator.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/coordinator .
EXPOSE 8080
CMD ["./coordinator"]
