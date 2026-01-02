# Framework Official Guidelines

Tài liệu này là **bản chuẩn chính thức** cho framework microservice Golang.

---

# 1. NAMING_CONVENTION.md

## 1.1 Nguyên tắc cốt lõi

* Nhất quán toàn hệ thống
* Tên phản ánh **domain + responsibility**
* Ưu tiên rõ ràng hơn ngắn gọn
* Không viết tắt nếu không phải thuật ngữ phổ biến (ID, API, URL)

---

## 1.2 Git Repository / Microservice

**Format chuẩn:**

```
<domain>-<capability>-service
```

**Ví dụ đúng:**

* `auth-service`
* `file-storage-service`
* `crm-customer-service`
* `hrm-employee-service`

**Không được dùng:**

* `auth`
* `customer-service`
* `crm-service`

📌 Mỗi service chỉ có **1 responsibility rõ ràng**.

---

## 1.3 Golang Package

* lowercase
* số ít
* 1 package = 1 vai trò

```go
handler
usecase
repository
model
middleware
infrastructure
```

❌ Cấm:

```
utils
common
helpers
```

---

## 1.4 File

**Format:**

```
<entity>_<layer>.go
```

Ví dụ:

* `user_handler.go`
* `user_usecase.go`
* `user_repository.go`

---

## 1.5 Struct / Interface

```go
type User struct {}
type LoginRequest struct {}

type UserRepository interface {}
type TokenGenerator interface {}
```

* Struct: danh từ
* Interface: hành vi rõ ràng

---

## 1.6 Function / Method

* Public: PascalCase
* Private: camelCase
* Bắt đầu bằng **động từ**

```go
CreateUser()
VerifyToken()
GenerateAccessToken()
```

---

## 1.7 API Endpoint

```
/api/v1/<resource>/<action>
```

Ví dụ:

* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `GET /api/v1/users/{id}`

---

## 1.8 MongoDB

**Collection:** snake_case, số nhiều

```
users
login_sessions
```

**Field:** camelCase

```json
{
  "createdTime": 1710000000,
  "lastUpdateTime": 1710000100
}
```

---

# 2. SERVICE_TEMPLATE/

## 2.1 Mục tiêu

* Tạo service mới trong **< 5 phút**
* Không cần suy nghĩ cấu trúc
* Bắt buộc đúng convention

---

## 2.2 Cấu trúc repo mẫu

```
SERVICE_TEMPLATE/
├── cmd/server/main.go
├── internal/
│   ├── handler/
│   ├── usecase/
│   ├── repository/
│   ├── model/
│   ├── middleware/
│   ├── config/
│   └── infrastructure/
├── api/openapi.yaml
├── deploy/
│   ├── docker/
│   └── k8s/
├── Makefile
├── README.md
```

---

## 2.3 Quy trình tạo service mới

1. Copy `SERVICE_TEMPLATE`
2. Rename repo theo naming convention
3. Update:

    * `module name`
    * `serviceName`
    * `openapi.yaml`
4. Run:

```bash
make dev
```

---

# 3. LOCAL_DEV_SHARED_INFRA.md

## 3.1 Mục tiêu

* Dev local **không cần Docker / K8s / DB**
* Tất cả dev dùng **shared DB & queue**
* Chấp nhận race condition để test luồng thật

---

## 3.2 Kiến trúc

```
Local Service (Go)
   |
   | ENV CONFIG
   v
Dev Infra Proxy
   |
   +-- MongoDB (shared)
   +-- Redis / Queue (shared)
```

---

## 3.3 Cấu hình ENV

```env
APP_ENV=dev-shared
DB_URI=mongodb://dev-proxy.internal
REDIS_ADDR=dev-proxy.internal:6379
QUEUE_ENDPOINT=dev-proxy.internal
```

📌 Không hardcode endpoint trong code.

---

## 3.4 Quy ước dữ liệu khi dùng shared DB

* Bắt buộc có:

```go
env
serviceName
```

* Query luôn filter theo env + service

---

# 4. CI_ENFORCEMENT.md

## 4.1 Mục tiêu

* Fail build nếu sai convention
* Không phụ thuộc ý thức cá nhân

---

## 4.2 CI Rule bắt buộc

### Golang

* `golangci-lint`
* Custom rule:

    * Cấm package `utils`
    * Cấm DB call trong handler

### Naming

* Check repo name regex
* Check file name regex

### API

* Validate OpenAPI
* Detect breaking change

---

## 4.3 Nguyên tắc

> Code không đúng chuẩn = không được merge

---

**Owner:** Core Platform Team
**Status:** Active
**Version:** v1.0
