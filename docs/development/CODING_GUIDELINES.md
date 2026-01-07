# FRAMEWORK OFFICIAL GUIDELINES

**Golang Microservice Framework – Internal Engineering Standard**

***

## Phạm vi & đối tượng áp dụng

Tài liệu này áp dụng cho:

* Tất cả microservice viết bằng **Golang**
* Bao gồm:
    * Platform services (auth, iam, file, notification, object-storage…)
    * Business services (crm, hrm, lms, billing…)
* Áp dụng cho **mọi môi trường**: local, dev, staging, prod

***

## 1\. Triết lý thiết kế \(Design Philosophy\)

### 1.1 Production-first mindset

Framework được thiết kế với tư duy:

> **Code phải chịu được môi trường production ngay từ lúc dev**

Do đó:

* Không tạo môi trường dev “quá sạch”
* Không che giấu race condition
* Không giả lập hành vi hệ thống

***

### 1.2 Chaos-aware development

Framework **chủ động chấp nhận**:

* Concurrent requests
* Duplicate events
* Partial failure
* Eventual consistency

👉 Dev phải **xử lý bằng code**, không né tránh bằng môi trường.

***

## 2\. Kiến trúc tổng thể \(High\-level Architecture\)

### 2.1 Microservice đúng nghĩa

Mỗi service:

* Có **domain rõ ràng**
* Có **API contract riêng**
* Có **database riêng (schema riêng)**

❌ Không chia sẻ database schema
❌ Không query DB của service khác

***

### 2.2 Gateway-centric architecture

* Frontend **chỉ gọi API Gateway**
* Gateway chịu trách nhiệm:
    * CORS
    * Authentication / Authorization
    * Tenant mapping
    * Rate limiting
    * Routing

Microservice phía sau:

* Tin tưởng gateway
* Không xử lý CORS
* Không validate origin

***

## 3\. LOCAL DEVELOPMENT RULES \(CỐT LÕI\)

> Mục tiêu:
> **Dev local nhẹ – code chạy thật – infra dùng chung**

***

### Rule 3.1 – Không yêu cầu dev cài hạ tầng

Dev **KHÔNG BẮT BUỘC** phải cài:

* Kubernetes
* MongoDB / PostgreSQL
* Redis / Kafka / RabbitMQ
* API Gateway

Dev chỉ cần:

* Golang
* Editor
* Network access tới infra dùng chung

***

### Rule 3.2 – Service local chạy như production

Service chạy local:

```
go run cmd/api/main.go
```

Yêu cầu:

* Không code path riêng cho local
* Không mock DB
* Không mock queue

👉 Code local = code prod

***

### Rule 3.3 – Mọi kết nối phải qua config

Tất cả hạ tầng phải cấu hình qua:

* ENV
* Config file (YAML / TOML)

Ví dụ:

```
database:
  mongoUri: mongodb://dev-shared.mongo.internal:27017/app

queue:
  redisUri: redis://dev-shared.redis.internal:6379
```

❌ Cấm hard-code
❌ Cấm switch logic bằng hostname

***

## ⭐ Rule 3.4 – SHARED INFRA DEVELOPMENT (QUY ƯỚC ĐẶC BIỆT)

> **TẤT CẢ DEV DÙNG CHUNG DB & QUEUE**
> **KHÔNG CHIA ENV**
> **KHÔNG TÁCH API**

Đây là **quy ước có chủ đích**, không phải thiếu sót.

***

### 3.4.1 Mục tiêu của Rule 3.4

Rule này tồn tại để:

* Mọi dev nhìn thấy **cùng một trạng thái hệ thống**
* Phát hiện:
    * race condition
    * duplicate event
    * dirty write
* Tránh tình trạng:

  > “local chạy ok, lên prod chết”

***

### 3.4.2 Hệ quả DEV PHẢI CHẤP NHẬN

| Hệ quả | Trạng thái |
| ------ | ---------- |
| Data không sạch | CHẤP NHẬN |
| Concurrent insert | CHẤP NHẬN |
| Log lẫn nhau | CHẤP NHẬN |
| Test phá dữ liệu | KHÔNG CHẤP NHẬN |

***

### 3.4.3 Quy tắc bắt buộc khi dùng chung DB

#### (1) Không được giả định DB rỗng

Code **KHÔNG ĐƯỢC**:

* assume first insert
* assume auto increment
* assume empty collection

***

#### (2) Idempotency là bắt buộc

Mọi API quan trọng phải:

* retry-safe
* xử lý duplicate key

Ví dụ:

* unique index
* upsert
* version field

***

#### (3) Không truncate / reset dữ liệu

❌ Không drop collection
❌ Không reset database
Chỉ dùng:

* logical delete
* versioning

***

#### (4) Phải có audit metadata

Mọi record phải có:

```
createdAt
updatedAt
createdBy
requestId
```

***

### 3.4.4 Race condition là “bài test tự nhiên”

Framework coi:

* race condition
* concurrent update

👉 là **bài test tự nhiên** cho chất lượng code.
Dev **không được né** bằng env riêng.

***

## 4\. Source Code Organization Rules

### 4.1 Mỗi service = 1 repo

* Repo độc lập
* Version độc lập
* CI/CD độc lập

***

### 4.2 Cấu trúc thư mục chuẩn

```
.
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── domain/        # entity, aggregate
│   ├── service/       # business logic
│   ├── repository/    # DB access
│   ├── transport/
│   │   └── http/
│   └── app/           # wire dependencies
├── pkg/               # reusable packages
├── config/
├── docs/
└── README.md
```

***

## 5\. Naming Convention Rules

### 5.1 Service naming

```
go-auth-service
go-file-service
go-crm-service
```

* lowercase
* kebab-case
* không thêm env suffix

***

### 5.2 API naming

```
GET  /v1/users
POST /v1/users
```

* RESTful
* versioned
* noun-based

***

### 5.3 Database naming (MongoDB)

| Thành phần | Quy ước |
| ---------- | ------- |
| Database | snake\_case |
| Collection | snake\_case |
| Field | camelCase |

***

## 6\. Testing Rules

### 6.1 Unit test

* Test business logic
* Không connect DB

***

### 6.2 Integration test

* Dùng DB thật
* Dùng shared DB

***

### 6.3 Contract test

* Validate OpenAPI
* Đảm bảo backward compatibility

***

### 6.4 CORS test

* **CHỈ test tại API Gateway**
* Không test trong service

***

## 7\. CI/CD Enforcement Rules

Build sẽ **FAIL** nếu:

* Không có OpenAPI spec
* Sai naming
* Hard-code config
* Truy cập DB service khác
* Không xử lý duplicate key

***

## 8\. Security Rules

* Không log secret
* Không expose internal error
* Auth chỉ xử lý tại gateway

***

## 9\. Vai trò của API Gateway

Gateway chịu trách nhiệm:

* CORS
* Auth
* Tenant mapping
* Rate limit

Service phía sau:

* Tin gateway
* Focus business