-- Chạy riêng lệnh này để tạo Database và Schema cho ClickHouse
DROP DATABASE IF EXISTS telemetry;
CREATE DATABASE IF NOT EXISTS telemetry ENGINE = Atomic;

-- Tạo Database chuyên biệt cho dữ liệu quan sát (Observability)
CREATE TABLE IF NOT EXISTS telemetry.auth_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    user_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
    impersonator_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',

    -- II. CHI TIẾT ĐĂNG NHẬP
    email_attempted String,
    ip_address IPv6,
    user_agent String,

    -- III. KẾT QUẢ & PHƯƠNG THỨC (Dùng Enum để tối ưu)
    is_success Bool,
    login_method Enum8(
        'PASSWORD' = 1,
        'GOOGLE' = 2,
        'SSO' = 3,
        'MAGIC_LINK' = 4,
        'PASSKEY' = 5
    ),
    failure_reason Enum8(
        'NONE' = 0,
        'WRONG_PASSWORD' = 1,
        'MFA_FAILED' = 2,
        'USER_LOCKED' = 3,
        'INVALID_TOKEN' = 4
    ),

    -- IV. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
    -- Skipping index: Bloom filter for quick email lookups during brute-force analysis
    ,
    INDEX idx_email_search email_attempted TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng quản lý vòng đời (Retention Policy)
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant trước, thời gian sau để tối ưu truy vấn SaaS
ORDER BY (tenant_id, created_at, _id)
-- Cấu hình lưu trữ bổ sung (Tùy chọn)
SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.security_audit_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    actor_id UUID,
    impersonator_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',

    -- II. CHI TIẾT SỰ KIỆN (Dùng Enum để nén dữ liệu cực tốt)
    event_category Enum8(
        'IAM' = 1,
        'AUTH' = 2,
        'BILLING' = 3,
        'DATA' = 4,
        'SYSTEM' = 5
    ),
    event_action String,
    target_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
    resource_type String,

    -- III. THÔNG TIN MÔI TRƯỜNG
    ip_address IPv6,
    user_agent String,
    details String, -- Lưu JSON thô

    -- IV. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
    -- Skipping indexes for fast lookup
    ,
    INDEX idx_event_action event_action TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_target_lookup target_id TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng theo tháng để tối ưu việc xóa dữ liệu cũ (Data Archiving)
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant và Thời gian để phục vụ query Dashboard SaaS nhanh nhất
ORDER BY (tenant_id, created_at, _id)

SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.api_usage_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    app_code String,

    -- II. CHI TIẾT GIAO DỊCH API
    api_endpoint String,
    api_method Enum8(
        'GET' = 1,
        'POST' = 2,
        'PUT' = 3,
        'DELETE' = 4,
        'PATCH' = 5,
        'OPTIONS' = 6
    ),
    status_code Int16,

    -- III. METRICS (Để tính tiền Bandwidth & Quota)
    request_size Int64 DEFAULT 0,
    response_size Int64 DEFAULT 0,
    latency_ms Int32,

    -- IV. TRUY VẾT XÁC THỰC
    api_key_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',

    -- V. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
    -- Skipping indexes for endpoint and status filtering
    ,
    INDEX idx_endpoint_search api_endpoint TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_status_code status_code TYPE minmax GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa dữ liệu cũ (Retention Policy) [2], [7]
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant trước, mã ứng dụng và thời gian sau [7]
ORDER BY (tenant_id, app_code, created_at, _id)
-- Cấu hình hạt nhân cho chỉ mục

SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.webhook_delivery_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    webhook_id UUID,

    -- II. CHI TIẾT GỬI TIN
    event_type String,
    target_url String,
    payload String,
    response_body String,

    -- III. KẾT QUẢ VẬN HÀNH
    status_code Int16,
    is_success Bool,
    latency_ms Int32,
    attempt_number Int8 DEFAULT 1,

    -- IV. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
    -- Skipping indexes to accelerate webhook lookups and filtering
    ,
    INDEX idx_webhook_lookup webhook_id TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_status_code status_code TYPE minmax GRANULARITY 1,
    INDEX idx_url_search target_url TYPE tokenbf_v1(4096, 2, 0) GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa log cũ (Retention Policy) [2]
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant và Thời gian để phục vụ truy vấn Dashboard SaaS nhanh nhất [10]
ORDER BY (tenant_id, created_at, _id)
-- Cấu hình hạt nhân cho chỉ mục

SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.audit_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    user_id UUID,
    impersonator_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',

    -- II. CHI TIẾT SỰ KIỆN
    event_time DateTime64(3) DEFAULT now(),
    action String,
    resource String,
    resource_id Nullable(String),
    details String,

    -- III. CONTEXT & SECURITY
    ip_address String,
    user_agent String,
    status Enum8('SUCCESS' = 1, 'FAILED' = 2) DEFAULT 'SUCCESS'
    -- Skipping indexes for action and user lookups
    ,
    INDEX idx_action_search action TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_user_search user_id TYPE minmax GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa log cũ (Retention Policy) [9], [14]
PARTITION BY toYYYYMM(event_time)
-- Sắp xếp theo Tenant và Thời gian để tối ưu truy vấn tra soát [9], [11]
ORDER BY (tenant_id, event_time, _id)
-- Cấu hình hạt nhân cho chỉ mục

SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.user_registration_logs (
    _id UUID,
    tenant_id UUID,
    user_id UUID,
    registration_source Enum8('DIRECT' = 1, 'SSO' = 2, 'INVITE' = 3),
    data_region String,
    created_at DateTime64(3) DEFAULT now()
    -- Skipping index for geographic region
    ,
    INDEX idx_region data_region TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng theo tháng để quản lý vòng đời dữ liệu
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo tenant_id trước để khách hàng xem báo cáo của họ cực nhanh
ORDER BY (tenant_id, created_at, _id)

SETTINGS allow_nullable_key = 1, index_granularity = 8192;


CREATE TABLE IF NOT EXISTS telemetry.usage_events (
    -- 1. Định danh & Liên kết
    _id UUID,
    tenant_id UUID,
    subscription_id UUID,

    -- 2. Thông tin nghiệp vụ
    app_code String,
    event_type String, -- Hoặc Enum8('EMAIL_SENT' = 1, 'FILE_UPLOAD' = 2) để tối ưu dung lượng [11]
    quantity Decimal128(4),
    unit String,

    -- 3. Thông tin kỹ thuật & Metadata
    metadata String, -- Lưu JSON String, dùng hàm JSONExtract để truy vấn [11]
    data_region String,
    timestamp DateTime64(3, 'UTC')
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để tối ưu việc xóa/nén dữ liệu cũ [4, 16]
PARTITION BY toYYYYMM(timestamp)
-- Sắp xếp dữ liệu (Sorting Key) để truy vấn báo cáo theo Tenant và App cực nhanh [4]
ORDER BY (tenant_id, app_code, event_type, timestamp)
-- Cấu hình nén dữ liệu (Mặc định ClickHouse nén rất tốt, tỷ lệ ~10:1) [3]
SETTINGS allow_nullable_key = 1, index_granularity = 8192;

-- Lưu ý: ClickHouse không dùng Index truyền thống như SQL.
-- Sorting Key (ORDER BY) đóng vai trò là Primary Index giúp lọc dữ liệu trong mili-giây [3, 4].


CREATE TABLE IF NOT EXISTS telemetry.saas_business_reports (
    _id UUID,
    report_date Date32,
partner_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
    revenue_category Enum8('NEW' = 1, 'RENEWAL' = 2, 'UPGRADE' = 3, 'ADD_ON' = 4, 'COMMISSION' = 5),
    total_revenue Decimal128(4),
    currency_code FixedString(3) DEFAULT 'VND',
    tenant_count UInt32,
    details_json String DEFAULT '{}',
    created_at DateTime64(3, 'UTC') DEFAULT now()
    -- Skipping indexes to speed revenue range queries and JSON searches
    ,
    INDEX idx_revenue_minmax total_revenue TYPE minmax GRANULARITY 2,
    INDEX idx_details_search details_json TYPE tokenbf_v1(256, 2, 0) GRANULARITY 1
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để tối ưu việc xóa/truy xuất dữ liệu cũ
PARTITION BY toYYYYMM(report_date)
-- Sắp xếp dữ liệu theo ngày và loại doanh thu để biểu đồ load nhanh nhất
ORDER BY (report_date, partner_id, revenue_category, _id)

SETTINGS allow_nullable_key = 1, index_granularity = 8192;



CREATE TABLE IF NOT EXISTS telemetry.traffic_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    user_id UUID DEFAULT '00000000-0000-0000-0000-000000000000',
    app_code String,

    -- II. CHI TIẾT GIAO DỊCH HTTP
    method Enum8(
        'GET' = 1, 'POST' = 2, 'PUT' = 3, 'DELETE' = 4,
        'PATCH' = 5, 'OPTIONS' = 6, 'HEAD' = 7
    ),
    domain String,
    path String,
    status_code Int16,

    -- III. METRICS & PERFORMANCE
    latency_ms Int32,
    request_size Int64 DEFAULT 0,
    response_size Int64 DEFAULT 0,

    -- IV. CONTEXT & SECURITY
    ip_address IPv6,
    user_agent String,
    data_region String DEFAULT 'ap-southeast-1',

    -- V. THỜI GIAN
    timestamp DateTime64(3, 'UTC') DEFAULT now()
    -- Skipping indexes for domain/path, status and IP filtering
    ,
    INDEX idx_domain_path (domain, path) TYPE tokenbf_v1(4096, 2, 0) GRANULARITY 1,
    INDEX idx_status_code status_code TYPE minmax GRANULARITY 1,
    INDEX idx_ip_search ip_address TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = MergeTree()

-- Phân vùng dữ liệu theo tháng để dễ dàng dọn dẹp log cũ (Retention Policy)
PARTITION BY toYYYYMM(timestamp)

-- Sắp xếp tối ưu cho truy vấn Dashboard theo từng Tenant và Ứng dụng
ORDER BY (tenant_id, app_code, timestamp, _id)

-- Cấu hình hạt nhân cho chỉ mục thưa

SETTINGS allow_nullable_key = 1, index_granularity = 8192;
