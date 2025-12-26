# Tài Liệu Tiếng Việt - Go DevTools

Chào mừng bạn đến với tài liệu tiếng Việt cho go-framework!

## 📚 Mục Lục Tài Liệu

### Bắt Đầu
- **[Hướng Dẫn Bắt Đầu Nhanh](#hướng-dẫn-bắt-đầu-nhanh)** - Thiết lập và chạy trong 10 phút
- **[Hướng Dẫn Cho Người Mới](#hướng-dẫn-cho-người-mới)** - Giới thiệu các công nghệ cơ bản

### Phát Triển
- **[Hướng Dẫn Tạo Service Mới](NEW_SERVICE_GUIDE.md)** - Tạo microservice mới
- **[Quy Trình Phát Triển](#quy-trình-phát-triển)** - Workflow hàng ngày
- **[Kiểm Thử và Debugging](#kiểm-thử-và-debugging)** - Test và debug code

### Kiến Trúc
- **[Tổng Quan Kiến Trúc](#tổng-quan-kiến-trúc)** - Thiết kế hệ thống
- **[Sơ Đồ Hệ Thống](#sơ-đồ-hệ-thống)** - Diagrams và visualizations

### Công Cụ
- **[Danh Sách Công Cụ](#danh-sách-công-cụ)** - Tất cả scripts và utilities
- **[Cấu Hình](#cấu-hình)** - Thiết lập môi trường

---

## 🚀 Hướng Dẫn Bắt Đầu Nhanh

### Yêu Cầu Hệ Thống

- **macOS**, **Linux**, hoặc **Windows với WSL2**
- **Docker Desktop** 20.10+
- **Go** 1.21+
- **Git**

### Cài Đặt Trong 3 Bước

#### Bước 1: Clone Repository

```bash
git clone https://github.com/vhvcorp/go-framework.git
cd go-framework
```

#### Bước 2: Chạy Script Cài Đặt Tự Động

```bash
# Chế độ tương tác (có hỏi)
./scripts/setup/interactive-setup.sh

# Chế độ nhanh (không hỏi, dùng mặc định)
./scripts/setup/interactive-setup.sh --quick

# Tùy chỉnh workspace
./scripts/setup/interactive-setup.sh --workspace ~/my-workspace
```

#### Bước 3: Khởi Động Services

```bash
# Khởi động tất cả services
make start

# Kiểm tra trạng thái
make status

# Xem logs
make logs
```

### ✅ Xác Minh Cài Đặt

```bash
# Kiểm tra health của tất cả services
./scripts/utilities/check-health.sh

# Mở Grafana dashboard
./scripts/monitoring/open-grafana.sh
```

**Xong! 🎉** Hệ thống của bạn đã sẵn sàng.

---

## 👶 Hướng Dẫn Cho Người Mới

### Các Công Nghệ Được Sử Dụng

#### 1. Docker - Container Hóa Ứng Dụng

**Docker là gì?**
Giống như "hộp cơm" đóng gói ứng dụng với tất cả dependencies, đảm bảo chạy giống nhau ở mọi nơi.

**Lệnh Cơ Bản:**
```bash
# Xem containers đang chạy
docker ps

# Khởi động container
docker start my-container

# Dừng container
docker stop my-container

# Xem logs
docker logs my-container
```

**Docker Compose:**
Quản lý nhiều containers cùng lúc.

```bash
# Khởi động tất cả services
docker-compose up -d

# Dừng tất cả
docker-compose down

# Xem logs tất cả services
docker-compose logs -f
```

#### 2. Go - Ngôn Ngữ Lập Trình

**Go là gì?**
Ngôn ngữ lập trình đơn giản, nhanh, được Google phát triển. Rất phù hợp cho backend và microservices.

**Hello World:**
```go
package main

import "fmt"

func main() {
    fmt.Println("Xin chào Việt Nam!")
}
```

**HTTP Server Đơn Giản:**
```go
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Xin chào, %s!", r.URL.Path[1:])
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
```

#### 3. MongoDB - NoSQL Database

**MongoDB là gì?**
Database lưu trữ dữ liệu dạng JSON, linh hoạt hơn SQL database truyền thống.

**Ví Dụ:**
```javascript
// Thêm user mới
db.users.insertOne({
    name: "Nguyễn Văn A",
    email: "nguyenvana@example.com",
    age: 25
})

// Tìm user
db.users.findOne({ email: "nguyenvana@example.com" })

// Cập nhật
db.users.updateOne(
    { email: "nguyenvana@example.com" },
    { $set: { age: 26 } }
)
```

#### 4. Redis - In-Memory Cache

**Redis là gì?**
Giống như "giấy note" siêu nhanh trong RAM, lưu dữ liệu tạm thời.

**Khi Nào Dùng:**
- Lưu session user
- Cache kết quả API
- Rate limiting
- Đếm số lượt xem

**Ví Dụ:**
```go
// Lưu giá trị
client.Set(ctx, "user:1:name", "Nguyễn Văn A", 1*time.Hour)

// Lấy giá trị
name, _ := client.Get(ctx, "user:1:name").Result()

// Tăng counter
client.Incr(ctx, "page:views")
```

#### 5. RabbitMQ - Message Queue

**RabbitMQ là gì?**
Như "bếp nhà hàng" - nhận orders (messages) và xử lý tuần tự.

**Tại Sao Dùng:**
- Xử lý bất đồng bộ
- Tách biệt services
- Retry khi lỗi
- Load balancing

**Ví Dụ:**
```go
// Gửi message
channel.Publish("", "task_queue", false, false,
    amqp.Publishing{
        ContentType: "text/plain",
        Body:        []byte("Xử lý đơn hàng #123"),
    })

// Nhận message
msgs, _ := channel.Consume("task_queue", "", false, false, false, false, nil)
for msg := range msgs {
    fmt.Printf("Nhận: %s\n", msg.Body)
    // Xử lý công việc
    msg.Ack(false)
}
```

#### 6. Microservices - Kiến Trúc

**Microservices là gì?**
Thay vì 1 ứng dụng lớn (monolith), chia thành nhiều services nhỏ, mỗi service làm 1 việc cụ thể.

**Ví Dụ Platform:**
```
┌─────────────────────────────────────┐
│         API Gateway                 │
│     (Cổng vào duy nhất)             │
└─────────────────────────────────────┘
           │
    ┌──────┴──────┬──────┬──────┬──────┐
    │             │      │      │      │
┌───▼───┐  ┌─────▼───┐ ┌▼────┐ ┌▼────┐ ┌▼────┐
│ Auth  │  │ User    │ │Order│ │Pay │ │Email│
│Service│  │ Service │ │Svc  │ │Svc │ │ Svc │
└───────┘  └─────────┘ └─────┘ └─────┘ └─────┘
```

**Lợi Ích:**
- Scale từng service riêng
- Deploy độc lập
- Công nghệ linh hoạt
- Team làm việc song song

#### 7. REST API - Giao Tiếp HTTP

**REST API là gì?**
Cách services giao tiếp qua HTTP với các quy ước chuẩn.

**HTTP Methods:**
- **GET** - Lấy dữ liệu (đọc)
- **POST** - Tạo mới
- **PUT** - Cập nhật toàn bộ
- **PATCH** - Cập nhật một phần
- **DELETE** - Xóa

**Ví Dụ:**
```bash
# Lấy danh sách users
GET /api/v1/users

# Tạo user mới
POST /api/v1/users
{
    "name": "Nguyễn Văn A",
    "email": "nguyenvana@example.com"
}

# Lấy user cụ thể
GET /api/v1/users/123

# Cập nhật user
PUT /api/v1/users/123
{
    "name": "Nguyễn Văn B"
}

# Xóa user
DELETE /api/v1/users/123
```

**Status Codes:**
- **200 OK** - Thành công
- **201 Created** - Tạo mới thành công
- **400 Bad Request** - Request sai
- **401 Unauthorized** - Chưa đăng nhập
- **403 Forbidden** - Không có quyền
- **404 Not Found** - Không tìm thấy
- **500 Internal Server Error** - Lỗi server

#### 8. JWT - Authentication

**JWT là gì?**
JSON Web Token - như "thẻ ra vào" được mã hóa để xác thực user.

**Cấu Trúc:**
```
header.payload.signature
```

**Ví Dụ:**
```go
// Tạo token khi login
token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
    "user_id": "123",
    "email": "user@example.com",
    "exp": time.Now().Add(24 * time.Hour).Unix(),
})
tokenString, _ := token.SignedString([]byte("secret-key"))

// Verify token
token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
    return []byte("secret-key"), nil
})
```

#### 9. Prometheus & Grafana - Monitoring

**Prometheus:**
Thu thập metrics (số liệu) từ services.

**Grafana:**
Hiển thị metrics dạng đồ thị đẹp.

**Metrics Quan Trọng:**
- Request count (số request)
- Response time (thời gian phản hồi)
- Error rate (tỷ lệ lỗi)
- CPU/Memory usage
- Active users

**Ví Dụ Thêm Metrics:**
```go
import "github.com/prometheus/client_golang/prometheus"

// Tạo counter
var httpRequests = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "http_requests_total",
        Help: "Tổng số HTTP requests",
    },
    []string{"method", "endpoint"},
)

// Tăng counter
httpRequests.WithLabelValues("GET", "/api/users").Inc()
```

#### 10. Makefile - Tự Động Hóa

**Makefile là gì?**
File định nghĩa các lệnh ngắn gọn thay vì gõ dài.

**Ví Dụ:**
```makefile
.PHONY: start stop restart

# Khởi động services
start:
	docker-compose up -d
	@echo "✅ Services đã khởi động"

# Dừng services
stop:
	docker-compose down
	@echo "✅ Services đã dừng"

# Restart services
restart: stop start

# Build code
build:
	go build -o bin/server cmd/server/main.go

# Chạy tests
test:
	go test -v ./...
```

**Sử Dụng:**
```bash
make start   # Thay vì: docker-compose up -d
make stop    # Thay vì: docker-compose down
make test    # Thay vì: go test -v ./...
```

---

## 🏗️ Tổng Quan Kiến Trúc

### Kiến Trúc Microservices

```
                    ┌─────────────────┐
                    │   API Gateway   │
                    │    (Port 8000)  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
│  Auth Service  │  │  User Service  │  │ Order Service  │
│  (Port 8081)   │  │  (Port 8082)   │  │  (Port 8083)   │
└───────┬────────┘  └───────┬────────┘  └───────┬────────┘
        │                   │                    │
        └─────────┬─────────┴────────────────────┘
                  │
        ┌─────────▼──────────┐
        │    Data Layer      │
        │  - MongoDB         │
        │  - Redis           │
        │  - RabbitMQ        │
        └────────────────────┘
```

### Services

1. **API Gateway** (8000) - Điểm vào duy nhất
2. **Auth Service** (8081) - Xác thực & phân quyền
3. **User Service** (8082) - Quản lý users
4. **Order Service** (8083) - Quản lý đơn hàng
5. **Payment Service** (8084) - Xử lý thanh toán
6. **Notification Service** (8085) - Gửi thông báo

### Infrastructure

- **MongoDB** (27017) - Primary database
- **Redis** (6379) - Cache & sessions
- **RabbitMQ** (5672) - Message queue
- **Prometheus** (9090) - Metrics collection
- **Grafana** (3000) - Metrics visualization
- **Jaeger** (16686) - Distributed tracing

---

## 🛠️ Danh Sách Công Cụ

### Scripts Thiết Lập (`scripts/setup/`)

#### `install-deps.sh`
Cài đặt dependencies hệ thống.

```bash
./scripts/setup/install-deps.sh
```

#### `install-tools.sh`
Cài đặt development tools.

```bash
./scripts/setup/install-tools.sh
```

#### `init-workspace.sh`
Khởi tạo workspace.

```bash
./scripts/setup/init-workspace.sh /path/to/workspace
```

#### `interactive-setup.sh` ⭐ MỚI
Setup tương tác với parameters.

```bash
# Chế độ tương tác
./scripts/setup/interactive-setup.sh

# Chế độ nhanh
./scripts/setup/interactive-setup.sh --quick

# Tùy chỉnh
./scripts/setup/interactive-setup.sh \
  --workspace ~/workspace \
  --skip-repos \
  --skip-seed
```

### Scripts Phát Triển (`scripts/dev/`)

#### `wait-for-services.sh`
Đợi services sẵn sàng.

```bash
./scripts/dev/wait-for-services.sh
```

#### `restart-service.sh`
Restart service cụ thể.

```bash
./scripts/dev/restart-service.sh auth-service
```

#### `create-service.sh` ⭐ MỚI
Tạo service mới.

```bash
# Tạo service cơ bản
./scripts/dev/create-service.sh my-service

# Service đầy đủ
./scripts/dev/create-service.sh my-service \
  --port 8080 \
  --database mongodb \
  --with-grpc \
  --with-messaging
```

### Scripts Database (`scripts/database/`)

#### `seed.sh`
Seed dữ liệu mẫu.

```bash
./scripts/database/seed.sh
```

#### `backup.sh`
Backup database.

```bash
./scripts/database/backup.sh
```

#### `restore.sh`
Restore từ backup.

```bash
./scripts/database/restore.sh backup-file.tar.gz
```

### Scripts Testing (`scripts/testing/`)

#### `run-unit-tests.sh`
Chạy unit tests.

```bash
./scripts/testing/run-unit-tests.sh
```

#### `run-integration-tests.sh`
Chạy integration tests.

```bash
./scripts/testing/run-integration-tests.sh
```

#### `run-e2e-tests.sh`
Chạy end-to-end tests.

```bash
./scripts/testing/run-e2e-tests.sh
```

### Scripts Monitoring (`scripts/monitoring/`)

#### `open-grafana.sh`
Mở Grafana dashboard.

```bash
./scripts/monitoring/open-grafana.sh
```

---

## 🎯 Quy Trình Phát Triển

### 1. Tạo Service Mới

```bash
# Tạo service với generator
./scripts/dev/create-service.sh product-service \
  --port 8086 \
  --database mongodb \
  --with-cache

# Di chuyển vào service
cd ../services/product-service

# Cài đặt dependencies
go mod download
```

### 2. Phát Triển Local

```bash
# Copy environment file
cp .env.example .env

# Chỉnh sửa cấu hình
vim .env

# Chạy service
make run

# Hoặc với hot reload
make dev
```

### 3. Viết Code

```go
// internal/service/service.go
func (s *Service) CreateProduct(ctx context.Context, name string, price float64) (*model.Product, error) {
    // Validate
    if name == "" {
        return nil, errors.New("tên sản phẩm là bắt buộc")
    }
    
    if price <= 0 {
        return nil, errors.New("giá phải lớn hơn 0")
    }
    
    // Tạo product
    product := &model.Product{
        Name:  name,
        Price: price,
    }
    
    // Lưu vào database
    if err := s.repo.Create(ctx, product); err != nil {
        return nil, err
    }
    
    return product, nil
}
```

### 4. Viết Tests

```go
// internal/service/service_test.go
func TestCreateProduct(t *testing.T) {
    tests := []struct {
        name        string
        productName string
        price       float64
        wantErr     bool
    }{
        {"hợp lệ", "Sản phẩm A", 100.0, false},
        {"tên rỗng", "", 100.0, true},
        {"giá âm", "Sản phẩm B", -10.0, true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := svc.CreateProduct(ctx, tt.productName, tt.price)
            if (err != nil) != tt.wantErr {
                t.Errorf("CreateProduct() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 5. Chạy Tests

```bash
# Unit tests
make test-unit

# Integration tests
make test-integration

# Tất cả tests với coverage
make test-coverage
```

### 6. Build và Deploy

```bash
# Build binary
make build

# Build Docker image
make docker-build

# Run trong Docker
make docker-run

# Push lên registry
make docker-push
```

---

## 🧪 Kiểm Thử và Debugging

### Unit Testing

```bash
# Chạy tất cả unit tests
go test -v ./...

# Test một package cụ thể
go test -v ./internal/service

# Với coverage
go test -v -cover ./...

# Coverage report HTML
go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Integration Testing

```bash
# Chạy integration tests
go test -v -tags=integration ./tests/integration/

# Với Docker
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

### Debugging

**VS Code:**

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Service",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "program": "${workspaceFolder}/cmd/server",
            "env": {
                "PORT": "8080",
                "DB_HOST": "localhost"
            }
        }
    ]
}
```

**Delve CLI:**

```bash
# Cài đặt delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug
dlv debug cmd/server/main.go

# Trong delve
(dlv) break main.main
(dlv) continue
(dlv) print variable
(dlv) next
```

---

## 📊 Sơ Đồ Hệ Thống

### Xem Sơ Đồ PlantUML

Có 3 sơ đồ kiến trúc:

1. **system-architecture.puml** - Kiến trúc tổng thể
2. **installation-flow.puml** - Quy trình cài đặt
3. **data-flow.puml** - Luồng dữ liệu

**Cách Xem:**

```bash
# Online (không cần cài đặt)
# Mở http://www.plantuml.com/plantuml/uml/
# Copy nội dung file .puml và paste

# VS Code (cài extension)
# 1. Cài PlantUML extension
# 2. Mở file .puml
# 3. Nhấn Alt+D để xem preview

# CLI (cần Java)
plantuml docs/diagrams/system-architecture.puml

# Docker
docker run -it --rm -v $(pwd):/data plantuml/plantuml docs/diagrams/*.puml
```

---

## ⚙️ Cấu Hình

### Biến Môi Trường

Tất cả services đều đọc từ file `.env`:

```bash
# Server
PORT=8080
ENV=development

# Database
DB_HOST=localhost
DB_PORT=27017
DB_NAME=myservice
DB_USER=admin
DB_PASSWORD=secret

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@localhost:5672/

# Observability
PROMETHEUS_PORT=2112
JAEGER_ENDPOINT=http://localhost:14268/api/traces
```

### Docker Compose

```yaml
version: '3.8'

services:
  my-service:
    build: .
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - DB_HOST=mongodb
    depends_on:
      - mongodb
      - redis
    
  mongodb:
    image: mongo:5.0
    ports:
      - "27017:27017"
    
  redis:
    image: redis:6.2-alpine
    ports:
      - "6379:6379"
```

---

## 🎓 Học Thêm

### Tài Liệu Tiếng Anh

- [NEW_SERVICE_GUIDE.md](../NEW_SERVICE_GUIDE.md) - Hướng dẫn chi tiết
- [BEGINNER_GUIDE.md](../BEGINNER_GUIDE.md) - Cho người mới
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Kiến trúc hệ thống
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Quy trình phát triển
- [TESTING.md](../TESTING.md) - Chiến lược testing
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Khắc phục sự cố

### Resources Học Go

- [Tour of Go](https://go.dev/tour/) - Interactive tutorial
- [Effective Go](https://go.dev/doc/effective_go) - Best practices
- [Go by Example](https://gobyexample.com/) - Code examples
- [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests/) - TDD approach

### Resources Docker

- [Docker Tutorial](https://www.docker.com/101-tutorial)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## 💬 Hỗ Trợ

### Gặp Vấn Đề?

1. **Kiểm tra logs:**
   ```bash
   make logs
   docker-compose logs -f service-name
   ```

2. **Kiểm tra health:**
   ```bash
   ./scripts/utilities/check-health.sh
   curl http://localhost:8080/health
   ```

3. **Xem tài liệu troubleshooting:**
   - [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

4. **Tạo issue:**
   - [GitHub Issues](https://github.com/vhvcorp/go-framework/issues)

### Liên Hệ

- **Issues:** https://github.com/vhvcorp/go-framework/issues
- **Pull Requests:** https://github.com/vhvcorp/go-framework/pulls

---

## 🤝 Đóng Góp

Chúng tôi hoan nghênh mọi đóng góp!

### Quy Trình

1. Fork repository
2. Tạo branch: `git checkout -b feature/tinh-nang-moi`
3. Commit changes: `git commit -m 'Thêm tính năng mới'`
4. Push branch: `git push origin feature/tinh-nang-moi`
5. Tạo Pull Request

### Coding Standards

- Tuân theo [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Viết tests cho code mới
- Update documentation
- Format code: `gofmt -w .`
- Lint: `golangci-lint run`

---

## 📝 License

Copyright © 2024 VHV Corp. All rights reserved.

---

**Chúc bạn code vui vẻ! 🚀🇻🇳**
