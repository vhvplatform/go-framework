FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /system-config-service

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /system-config-service .
EXPOSE 8085
EXPOSE 50055
CMD ["./system-config-service"]
