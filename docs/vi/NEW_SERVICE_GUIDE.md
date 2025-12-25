# Hướng Dẫn Phát Triển Service Mới

Hướng dẫn đầy đủ để tạo microservices mới trong nền tảng.

## Mục Lục

- [Bắt Đầu Nhanh](#bắt-đầu-nhanh)
- [Công Cụ Tạo Service](#công-cụ-tạo-service)
- [Cấu Trúc Service](#cấu-trúc-service)
- [Quy Trình Phát Triển](#quy-trình-phát-triển)
- [Danh Sách Kiểm Tra](#danh-sách-kiểm-tra)
- [Thực Hành Tốt Nhất](#thực-hành-tốt-nhất)

---

## Bắt Đầu Nhanh

### Sử Dụng Công Cụ Tạo Service (Khuyến Nghị)

Cách nhanh nhất để tạo service mới:

```bash
# Tạo service mới với tất cả mã boilerplate
./scripts/dev/create-service.sh my-service

# Hoặc dùng lệnh make
make create-service SERVICE=my-service

# Với các tùy chọn
./scripts/dev/create-service.sh my-service \
  --port 8080 \
  --database mongodb \
  --with-grpc \
  --with-messaging
```

**Những gì được tạo:**
- ✅ Cấu trúc dự án Go hoàn chỉnh
- ✅ Cấu hình Docker
- ✅ HTTP server với health endpoints
- ✅ gRPC server (tùy chọn)
- ✅ Kết nối database (MongoDB/PostgreSQL)
- ✅ Tích hợp Redis
- ✅ RabbitMQ messaging (tùy chọn)
- ✅ Prometheus metrics
- ✅ Jaeger tracing
- ✅ Template unit tests
- ✅ Makefile cho các tác vụ thông dụng
- ✅ README với tài liệu đầy đủ

## Công Cụ Tạo Service

### Cách Sử Dụng Cơ Bản

```bash
# Tạo service với cấu hình mặc định
./scripts/dev/create-service.sh user-service

# Chỉ định cổng
./scripts/dev/create-service.sh user-service --port 8085

# Với PostgreSQL thay vì MongoDB
./scripts/dev/create-service.sh user-service --database postgres
```

### Các Tùy Chọn Khả Dụng

| Tùy Chọn | Mô Tả | Mặc Định |
|---------|-------|----------|
| `--port PORT` | Cổng HTTP server | 8080 |
| `--grpc-port PORT` | Cổng gRPC server | 9090 |
| `--database TYPE` | Loại database (mongodb/postgres/none) | mongodb |
| `--with-grpc` | Bao gồm gRPC server | false |
| `--with-messaging` | Bao gồm RabbitMQ messaging | false |
| `--with-cache` | Bao gồm Redis caching | true |
| `--no-tests` | Bỏ qua tạo file test | false |
| `--output DIR` | Thư mục đầu ra | ../services |

Xem thêm tài liệu tiếng Anh: [NEW_SERVICE_GUIDE.md](../NEW_SERVICE_GUIDE.md)
