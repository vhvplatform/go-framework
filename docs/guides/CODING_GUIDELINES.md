# \# 📘 FRAMEWORK OFFICIAL GUIDELINES & ENGINEERING HANDBOOK \(V2\.0\)

**Golang Microservice Framework – Internal Engineering Standard**

***

## Phạm vi & đối tượng áp dụng

Tài liệu này là "nguồn sự thật duy nhất" áp dụng cho:

* Tất cả microservice viết bằng **Golang** (Platform & Business services).
* Tất cả kỹ sư phần mềm, DevOps, và cán bộ kiểm soát chất lượng (QA).
* Áp dụng thống nhất cho **mọi môi trường**: local, dev, staging, prod.

***

## 1\. Triết lý thiết kế \(Design Philosophy\)

### 1.1 Production-first mindset

Framework được thiết kế với tư duy: **Code phải chịu được môi trường production ngay từ máy của developer.**

* Không tạo môi trường dev “quá sạch” hay giả lập lý tưởng.
* Không che giấu race condition hay độ trễ mạng.
* **Hệ quả:** Nếu code chạy lỗi trên shared-infra vì dữ liệu của dev khác, đó là lỗi của code (chưa xử lý concurrency/idempotency), không phải lỗi môi trường.

### 1.2 Chaos-aware & Polyglot Persistence

* **Chấp nhận sự hỗn loạn:** Code phải xử lý được: Concurrent requests, Duplicate events (Kafka), Partial failure (gRPC timeout), và Eventual consistency.
* **Đúng việc - Đúng công cụ:** \* **YugabyteDB (ACID):** Cho dữ liệu nghiệp vụ quan trọng, tài chính, quan hệ.
    * **MongoDB (Flex):** Cho cấu hình Tenant, Metadata động, tài liệu không cấu trúc.
    * **ClickHouse (OLAP):** Cho Audit logs, Access logs, dữ liệu phân tích quy mô lớn.

***

## 2\. Kiến trúc tổng thể \(High\-level Architecture\)

### 2.1 Microservice đúng nghĩa (Data Isolation)

Mỗi service sở hữu **Domain rõ ràng** và **Database riêng** (Schema/Database độc lập).

* ❌ Không chia sẻ database schema.
* ❌ Không query trực tiếp DB của service khác. Mọi giao tiếp phải qua gRPC.

### 2.2 Gateway-centric & Auth Broker

* **API Gateway:** Là điểm đầu cuối duy nhất cho Frontend. Chịu trách nhiệm: CORS, Rate Limiting, Routing.
* **Auth Broker:** Gateway thực hiện đổi **Opaque Token** lấy **Internal JWT** (từ Redis L2).
* **Trust Boundary:** Các microservice phía sau tin tưởng hoàn toàn vào `Internal JWT` và `X-Tenant-ID` được chuyển tiếp từ Gateway qua gRPC Metadata.

***

## 3\. Quy chuẩn Dữ liệu & Đặt tên \(Data Standards\)

### 3.1 Naming Convention

| **Thành phần**           | **Quy ước**             | **Ví dụ**                       |
| ------------------------ | ----------------------- | ------------------------------- |
| **Database / Table**     | `snake_case` (Số nhiều) | `order_items`, `tenant_configs` |
| **Database Field**       | `snake_case`            | `user_id`, `created_at`         |
| **Golang Struct / JSON** | `camelCase`             | `UserId`, `createdAt`           |
| **Primary Key**          | `_id` (UUID v7)         | `018d1234-5678-7123...`         |

### 3.2 Standard Mixins (Các trường bắt buộc)

Mọi bản ghi nghiệp vụ (Yugabyte/Mongo) phải bao gồm:

* `_id`: UUID định danh duy nhất.
* `tenant_id`: Định danh Tenant (bắt buộc để isolation).
* `version`: Số nguyên phục vụ **Optimistic Locking** (chống ghi đè).
* `created_at / updated_at`: Thời gian UTC.
* `deleted_at`: Đánh dấu **Soft Delete**. Cấm dùng lệnh `DELETE` vật lý.

***

## 4\. Quản lý Phiên bản API \(Versioning Strategy\)

Hệ thống bắt buộc hỗ trợ đa phiên bản để đảm bảo tương thích ngược.

### 4.1 Cấu trúc thư mục Logic

Việc chia version thực hiện từ tầng Protobuf đến Transport:
Plaintext

```
internal/api/
├── grpc/
│   ├── v1/           # Implement service v1 (Stable)
│   └── v2/           # Implement service v2 (Logic mới/Breaking changes)
api/proto/
└── product/
    ├── v1/product.proto  # package api.product.v1
    └── v2/product.proto  # package api.product.v2
```

### 4.2 Breaking Changes

* Không được sửa đổi nội dung đã release của phiên bản cũ (v1).
* Nếu thay đổi kiểu dữ liệu hoặc xóa field, phải nâng cấp lên v2.
* Gateway điều hướng dựa trên path: `/api/v1/resource` -> Service Handler V1.

***

## 5\. LOCAL DEVELOPMENT RULES \(CỐT LÕI\)

> **Mục tiêu: Dev local nhẹ – infra dùng chung – code chạy thật**

### Rule 5.1 – Không cài đặt hạ tầng local

Dev không bắt buộc cài DB/Kafka/Redis local. Tất cả kết nối qua cấu hình (`.env.local`) trỏ về **Shared Infrastructure**.

### ⭐ Rule 5.2 – Shared Infra Development (Quy ước đặc biệt)

**Tất cả dev dùng chung DB & Queue. Không chia Env riêng.**

* **Namespace kỷ luật:** Mọi key Redis/Kafka phải có prefix: `{tenant_id}:{service_name}:{dev_name}:{key}`.
* **Hệ quả chấp nhận:** Data không sạch, Log lẫn nhau, Concurrent insert từ dev khác.
* **Cấm kỵ:** Không được giả định DB rỗng; Không được Truncate/Reset database chung.

### Rule 5.3 – Idempotency là bắt buộc

Mọi API xử lý dữ liệu (CUD) phải:

* **Retry-safe:** Gọi lại nhiều lần không gây sai lệch (Dùng Unique Index, Upsert).
* **Audit Metadata:** Phải có `requestId` và `correlation_id` trong mọi bản ghi.

***

## 6\. Cơ chế Caching \(2\-Level Cache\)

Để đạt hiệu năng cao nhất, mọi service phải áp dụng:

1. **Level 1 (Local Cache):** Dùng `Ristretto` (In-memory). Truy cập <0.1ms. Dùng cho dữ liệu "hot" hoặc cấu hình ít thay đổi.
2. **Level 2 (Distributed Cache):** Dùng `Redis`. Dùng chung cho toàn bộ cluster của service.
3. **Consistency:** Khi update dữ liệu, xóa L2 và bắn Pub/Sub để các instance xóa L1 tương ứng.

***

## 7\. Logging & Observability

* **Correlation ID:** API Gateway sinh ra ID duy nhất. ID này phải được propagate qua context và in ra trong mọi dòng log của mọi service liên quan.
* **Structured Logging:** Sử dụng JSON format. Không log dữ liệu nhạy cảm (Password, Secret).
* **Audit Logs:** Ghi lại mọi thay đổi (Who, When, What, Old, New) vào **ClickHouse** thông qua Kafka (không đồng bộ).

***

## 8\. Source Code Organization \(Standard Layout\)

Plaintext

```
.
├── cmd/server/          # Entry point (Main, Wire DI)
├── internal/
│   ├── api/             # Transport Layer (gRPC, HTTP handlers)
│   ├── service/         # Business Logic (Pure Go)
│   ├── repository/      # Data Access (Yugabyte, Mongo, ClickHouse)
│   ├── model/           # Domain Entities (Internal structs)
│   └── platform/        # Shared library (Connectors, Log, Cache)
├── api/proto/           # Protobuf definitions (v1, v2...)
├── pkg/                 # SDK/Reusable code cho service khác
├── scripts/             # Migration, Build scripts
└── Makefile             # Lệnh thực thi chuẩn (gen, run, test)
```

***

## 9\. CI/CD Enforcement Rules \(Luật Build\)

Build sẽ **FAIL** tự động nếu vi phạm:

1. **Naming Violation:** DB field không phải `snake_case` hoặc PK không phải `_id`.
2. **Hard-coded Config:** Phát hiện IP, Port hoặc Secret cứng trong code.
3. **No Soft-Delete:** Sử dụng câu lệnh SQL `DELETE` trong code.
4. **API Contract:** Sửa đổi file `.proto` của phiên bản đã release (v1) gây breaking change.
5. **Security:** Không xử lý lỗi hoặc để lộ thông tin hệ thống trong error response.

***

## 10\. Security & Phân quyền

* **Auth xử lý tại Gateway:** Service phía sau tập trung vào nghiệp vụ.
* **Internal Claims:** Mọi service phải trích xuất `tenant_id`, `user_id`, và `permissions` từ `Internal-JWT` để thực hiện phân quyền nội bộ (RBAC/ABAC).

***

**Phê duyệt bởi:** System Architect
**Ngày hiệu lực:** 12/01/2026
**Trạng thái:** OFFICIAL STANDARD v2.0