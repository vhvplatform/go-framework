FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /auth-service

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /auth-service .
EXPOSE 8081
EXPOSE 50051
CMD ["./auth-service"]
