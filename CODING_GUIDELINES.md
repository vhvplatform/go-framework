# Framework Coding Convention Guidelines (Vietnamese)

## 1. Mục tiêu

Tài liệu này định nghĩa **chuẩn coding chính thức** cho framework microservice Golang của tổ chức, nhằm:

* Đồng nhất code giữa nhiều team
* Giảm conflict, giảm chi phí review
* Dễ maintain, scale và audit
* Phù hợp với kiến trúc microservice + Kubernetes + MongoDB

---

## 2. Nguyên tắc cốt lõi

* **Convention over configuration**
* **Explicit > Implicit**
* **Service độc lập – giao tiếp qua API**
* **Không import code chéo giữa các microservice**
* **Shared logic = lib nội bộ hoặc service nền tảng**

---

## 3. Quy ước đặt tên (Naming Convention – RẤT QUAN TRỌNG)

### 3.1 Nguyên tắc chung

* Tên phải **mô tả đúng bản chất**, không viết tắt mơ hồ
* Ưu tiên **tiếng Anh**, nhất quán toàn hệ thống
* Không dùng từ thừa: `data`, `info`, `object`, `manager` nếu không cần thiết
* Tránh trùng tên giữa các layer

---

### 3.2 Service / Repository

**Format:**

```
<domain>-<capability>-service
```

**Ví dụ đúng:**

* `auth-service`
* `file-storage-service`
* `crm-customer-service`
* `hrm-employee-service`

**Ví dụ sai:**

* `auth`
* `service-auth`
* `customer`

📌 *Lý do:*

* Nhìn repo là biết **domain + trách nhiệm**
* Phù hợp CI/CD, GitOps, Kubernetes naming

---

### 3.3 Package (Go)

**Quy tắc:**

* lowercase
* ngắn, đúng ngữ nghĩa
* 1 package = 1 responsibility

**Ví dụ:**

```go
package handler
package repository
package usecase
package middleware
```

❌ Không nên:

```go
package handlers
package utils
package common
```

---

### 3.4 File

**Format:**

```
<entity>_<layer>.go
```

**Ví dụ:**

* `user_handler.go`
* `user_repository.go`
* `user_usecase.go`
* `auth_middleware.go`

---

### 3.5 Struct / Interface

**Struct:** PascalCase, danh từ

```go
type User struct {}
type LoginRequest struct {}
```

**Interface:** PascalCase + hậu tố rõ nghĩa

```go
type UserRepository interface {}
type TokenGenerator interface {}
```

❌ Tránh:

```go
type IUserRepo struct {}
```

---

### 3.6 Function / Method

**Public:** PascalCase
**Private:** camelCase

```go
func CreateUser() {}
func validateToken() {}
```

📌 *Tên function nên bắt đầu bằng động từ*

* `Create`
* `Get`
* `Update`
* `Delete`
* `Verify`
* `Generate`

---

### 3.7 Biến (Variable)

* camelCase
* Tên phản ánh ý nghĩa

```go
var userID string
var tokenExpiredAt int64
```

❌ Tránh:

```go
var id string
var data interface{}
```

---

### 3.8 Constant

```go
const MaxLoginRetry = 5
const TokenTTLSeconds = 3600
```

---

### 3.9 API Endpoint

**Format:**

```
/api/v1/<resource>/<action>
```

**Ví dụ:**

* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `GET  /api/v1/users/{id}`

---

### 3.10 MongoDB Collection & Field

**Collection:** snake_case, số nhiều

```
users
login_sessions
```

**Field:** camelCase

```json
{
  "_id": "",
  "userId": "",
  "createdTime": 1710000000,
  "lastUpdateTime": 1710000100
}
```

📌 *Chuẩn thời gian:* Unix timestamp (int)

---

## 4. Cấu trúc thư mục chuẩn cho 1 microservice

```
cmd/
  server/
internal/
  handler/
  usecase/
  repository/
  model/
  middleware/
  config/
  infrastructure/
api/
  openapi.yaml
deploy/
  docker/
  k8s/
Makefile
README.md
```

---

## 5. Quy ước về Config

* Không hardcode
* Inject qua ENV
* Phân môi trường: dev / dev-shared / staging / prod

```env
DB_URI=
REDIS_ADDR=
QUEUE_ENDPOINT=
```

---

## 6. Logging & Error

* Log dạng JSON
* Có `traceId`, `service`, `env`
* Không log secret

---

## 7. Rule bắt buộc khi review code

* Không call DB trực tiếp từ handler
* Không dùng shared DB schema ngoài contract
* Không bypass auth middleware
* Không panic trong business logic

---

## 8. Versioning & Áp dụng

* Tài liệu này là **chuẩn bắt buộc**
* Mọi service mới phải tuân theo
* CI/CD sẽ enforce các rule chính

---

**Owner:** Core Platform Team
**Status:** Active
**Version:** v1.0
