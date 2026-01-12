# 🛡️ GLOBAL ARCHITECTURE RULES (FINAL - 2026)

Mọi code phát sinh trong Workspace này ĐỀU PHẢI tuân thủ các quy tắc sau:

## 1. Truy vấn & Xử lý dữ liệu (Context: #file:docs/database/*.md)
* **Standard Fields:** Tự động thêm Mixins: `_id` (UUID v7), `tenant_id`, `version`, `created_at`, `updated_at`, `deleted_at`. Tự động gán `updated_at` khi cập nhật và `deleted_at` khi Soft Delete.
* **Soft Delete:** Cấm lệnh `DELETE`. Luôn mặc định filter `deleted_at IS NULL`.
* **Naming:** DB dùng `snake_case`. Code/JSON dùng `camelCase`.
* **Tenant Isolation:** - Lấy `tenant_id` từ gRPC Metadata/Context (Auth Broker).
    - Mặc định: `WHERE tenant_id = current_tenant`. 
    - View-chéo: `WHERE tenant_id IN (sub_tenant_ids)` sau Authorization Check.
    - Kỷ luật: Cấm truy vấn thiếu điều kiện `tenant_id`.

## 2. Phân tầng Persistence (Context: #file:docs/architecture/NEW_ARCHITECHTURE.md)
* **YugabyteDB:** ACID/Transactions/Relational data.
* **MongoDB:** Tenant Config/Metadata/Schema-less.
* **ClickHouse:** Logging/Analytics ghi qua Kafka (Yêu cầu Retry & DLQ).

## 3. Giao tiếp & API (Context: #file:docs/guides/CODING_GUIDELINES.md)
* **Transport:** 100% gRPC + mTLS + `protoc-gen-validate`.
* **Pathing:** - Backend API: `/api/{service-name}/v{n}/{resource}`.
    - Web Page: `/page/{service-name}/{resource}` (KHÔNG có version).

## 4. Observability (OpenTelemetry)
* **Tracing:** Propagate `trace_id` & `span_id` xuyên suốt. Mọi log phải đính kèm `trace_id`.
* **Metrics:** Prometheus format cho các chỉ số nghiệp vụ quan trọng.

## 5. Hiệu năng & Config
* **2-Level Cache:** L1 (Ristretto) + L2 (Dragonfly). Namespace: `{tenant_id}:{service}:{dev_name}:{key}`.
* **Config:** Tuyệt đối không hardcode secret. Dùng Env Vars hoặc Vault qua struct `Config` tập trung.

## 6. Kỷ luật phát triển
* **No Hotfixes:** Không sửa tạm vi phạm kiến trúc. Phải fix tận gốc (Root Cause).
* **Error Handling:** Trả về gRPC Status hoặc `InternalError` từ `go-shared`. Cấm trả về raw error từ hệ thống.

## 7. Quy trình phản hồi (Mandatory Workflow)
1. **Context Check:** Đọc tài liệu dẫn chiếu trước khi đề xuất.
2. **Interface First:** Định nghĩa Interface tại Service/Domain layer trước.
3. **Tenant Context:** Xác định request là "Sở hữu" hay "Xem hộ".
4. **Explain:** Giải thích tính tuân thủ của code trước khi đưa ra block code.

## 8. Tài liệu (Documentation)
* **Update:** Cập nhật `docs/` kèm Lịch sử thay đổi `[YYYY-MM-DD] - [Author] - [Description]`.
* **OpenAPI:** Phải được generate từ Protobuf. Tên file dạng `kebab-case`.

## 9. Testing & Review
* **Testing:** Yêu cầu Unit, Contract (buf break), và Integration tests.
* **Review:** Kiểm tra nghiêm ngặt mTLS và Tenant Isolation.