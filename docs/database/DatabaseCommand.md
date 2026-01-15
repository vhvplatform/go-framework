# 1. Clickhouse command
CREATE TABLE auth_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    user_id Nullable(UUID),
    impersonator_id Nullable(UUID),

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
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng quản lý vòng đời (Retention Policy)
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant trước, thời gian sau để tối ưu truy vấn SaaS
ORDER BY (tenant_id, created_at, _id)
-- Cấu hình lưu trữ bổ sung (Tùy chọn)
SETTINGS index_granularity = 8192;

-- Tạo Index Bloom Filter cho trường email_attempted để tìm kiếm nhanh khi bị tấn công Brute-force
ALTER TABLE auth_logs ADD INDEX idx_email_search email_attempted TYPE bloom_filter(0.01) GRANULARIT


CREATE TABLE security_audit_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    actor_id UUID,
    impersonator_id Nullable(UUID),

    -- II. CHI TIẾT SỰ KIỆN (Dùng Enum để nén dữ liệu cực tốt)
    event_category Enum8(
        'IAM' = 1,
        'AUTH' = 2,
        'BILLING' = 3,
        'DATA' = 4,
        'SYSTEM' = 5
    ),
    event_action String,
    target_id Nullable(UUID),
    resource_type String,

    -- III. THÔNG TIN MÔI TRƯỜNG
    ip_address IPv6,
    user_agent String,
    details String, -- Lưu JSON thô

    -- IV. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
)
ENGINE = MergeTree()
-- Phân vùng theo tháng để tối ưu việc xóa dữ liệu cũ (Data Archiving)
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant và Thời gian để phục vụ query Dashboard SaaS nhanh nhất
ORDER BY (tenant_id, created_at, _id)
SETTINGS index_granularity = 8192;

-- 2. CHIẾN LƯỢC ĐÁNH INDEX BỔ SUNG (SKIPPING INDEX)

-- Index giúp tìm kiếm nhanh các hành động cụ thể trong hàng tỷ bản ghi
ALTER TABLE security_audit_logs
ADD INDEX idx_event_action event_action TYPE bloom_filter(0.01) GRANULARITY 1;

-- Index hỗ trợ tra cứu lịch sử tác động lên một tài nguyên cụ thể (target_id)
ALTER TABLE security_audit_logs
ADD INDEX idx_target_lookup target_id TYPE bloom_filter(0.01) GRANULARITY 1;


CREATE TABLE api_usage_logs (
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
    api_key_id Nullable(UUID),

    -- V. THỜI GIAN
    created_at DateTime64(3) DEFAULT now()
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa dữ liệu cũ (Retention Policy) [2], [7]
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant trước, mã ứng dụng và thời gian sau [7]
ORDER BY (tenant_id, app_code, created_at, _id)
-- Cấu hình hạt nhân cho chỉ mục
SETTINGS index_granularity = 8192;

-- 2. Tạo Skipping Index (Bloom Filter) cho api_endpoint
-- Giúp tìm kiếm nhanh các endpoint cụ thể khi phân tích hiệu năng mà không cần quét toàn bảng
ALTER TABLE api_usage_logs
ADD INDEX idx_endpoint_search api_endpoint TYPE bloom_filter(0.01) GRANULARITY 1;

-- 3. Tạo Skipping Index cho status_code
-- Phục vụ việc lọc nhanh các yêu cầu lỗi (status_code >= 400)
ALTER TABLE api_usage_logs
ADD INDEX idx_status_code status_code TYPE minmax GRANULARITY 1;


CREATE TABLE webhook_delivery_logs (
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
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa log cũ (Retention Policy) [2]
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo Tenant và Thời gian để phục vụ truy vấn Dashboard SaaS nhanh nhất [10]
ORDER BY (tenant_id, created_at, _id)
-- Cấu hình hạt nhân cho chỉ mục
SETTINGS index_granularity = 8192;

-- 2. CHIẾN LƯỢC ĐÁNH INDEX BỔ SUNG (SKIPPING INDEX)

-- Index giúp tìm kiếm nhanh các log liên quan đến một Webhook cụ thể trong hàng tỷ bản ghi
ALTER TABLE webhook_delivery_logs
ADD INDEX idx_webhook_lookup webhook_id TYPE bloom_filter(0.01) GRANULARITY 1;

-- Index hỗ trợ lọc nhanh các yêu cầu bị lỗi (status_code >= 400) để bắn cảnh báo [2]
ALTER TABLE webhook_delivery_logs
ADD INDEX idx_status_code status_code TYPE minmax GRANULARITY 1;

-- Index hỗ trợ tìm kiếm theo URL đích nếu khách hàng dùng nhiều endpoint
ALTER TABLE webhook_delivery_logs
ADD INDEX idx_url_search target_url TYPE tokenbf_v1(4096, 2, 0) GRANULARITY 1;


CREATE TABLE audit_logs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID,
    tenant_id UUID,
    user_id UUID,
    impersonator_id Nullable(UUID),

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
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để dễ dàng xóa log cũ (Retention Policy) [9], [14]
PARTITION BY toYYYYMM(event_time)
-- Sắp xếp theo Tenant và Thời gian để tối ưu truy vấn tra soát [9], [11]
ORDER BY (tenant_id, event_time, _id)
-- Cấu hình hạt nhân cho chỉ mục
SETTINGS index_granularity = 8192;

-- 2. Tạo Skipping Index cho trường 'action'
-- Giúp tìm kiếm nhanh các hành động cụ thể trong hàng tỷ bản ghi mà không cần quét toàn bảng
ALTER TABLE audit_logs
ADD INDEX idx_action_search action TYPE bloom_filter(0.01) GRANULARITY 1;

-- 3. Tạo Skipping Index cho trường 'user_id'
-- Giúp tra soát lịch sử của một nhân viên cụ thể nhanh hơn
ALTER TABLE audit_logs
ADD INDEX idx_user_search user_id TYPE minmax GRANULARITY 1;


CREATE TABLE user_registration_logs (
    _id UUID,
    tenant_id UUID,
    user_id UUID,
    registration_source Enum8('DIRECT' = 1, 'SSO' = 2, 'INVITE' = 3),
    data_region String,
    created_at DateTime64(3) DEFAULT now()
)
ENGINE = MergeTree()
-- Phân vùng theo tháng để quản lý vòng đời dữ liệu
PARTITION BY toYYYYMM(created_at)
-- Sắp xếp theo tenant_id trước để khách hàng xem báo cáo của họ cực nhanh
ORDER BY (tenant_id, created_at, _id)
SETTINGS index_granularity = 8192;

-- Index bổ sung để lọc nhanh theo vùng địa lý
ALTER TABLE user_registration_logs
ADD INDEX idx_region data_region TYPE bloom_filter(0.01) GRANULARITY 1;


CREATE TABLE usage_events (
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
SETTINGS index_granularity = 8192;

-- Lưu ý: ClickHouse không dùng Index truyền thống như SQL.
-- Sorting Key (ORDER BY) đóng vai trò là Primary Index giúp lọc dữ liệu trong mili-giây [3, 4].


CREATE TABLE saas_business_reports (
    _id UUID,
    report_date Date32,
partner_id Nullable(UUID),
    revenue_category Enum8('NEW' = 1, 'RENEWAL' = 2, 'UPGRADE' = 3, 'ADD_ON' = 4, 'COMMISSION' = 5),
    total_revenue Decimal128(4),
    currency_code FixedString(3) DEFAULT 'VND',
    tenant_count UInt32,
    details_json String DEFAULT '{}',
    created_at DateTime64(3, 'UTC') DEFAULT now()
)
ENGINE = MergeTree()
-- Phân vùng dữ liệu theo tháng để tối ưu việc xóa/truy xuất dữ liệu cũ
PARTITION BY toYYYYMM(report_date)
-- Sắp xếp dữ liệu theo ngày và loại doanh thu để biểu đồ load nhanh nhất
ORDER BY (report_date, partner_id, revenue_category, _id)
SETTINGS index_granularity = 8192;

-- 2. TẠO DATA SKIPPING INDEX (Hỗ trợ truy vấn sâu)
-- Giúp tăng tốc khi lọc các báo cáo có doanh thu lớn bất thường
ALTER TABLE saas_business_reports
ADD INDEX idx_revenue_minmax total_revenue TYPE minmax GRANULARITY 2;

-- Giúp tăng tốc khi tìm kiếm thông tin trong chuỗi JSON chi tiết
ALTER TABLE saas_business_reports
ADD INDEX idx_details_search details_json TYPE tokenbf_v1(256, 2, 0) GRANULARITY 1;


# 2. Yugabyte command

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE tenants (
    -- I. ĐỊNH DANH & HẠ TẦNG
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application
    code VARCHAR(64) NOT NULL,
    data_region VARCHAR(50) NOT NULL DEFAULT 'ap-southeast-1',
    compliance_level VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    parent_tenant_id UUID,
    path TEXT,
    -- II. THÔNG TIN NGHIỆP VỤ & ĐỊA PHƯƠNG HÓA
    name TEXT NOT NULL,
    tier VARCHAR(50) NOT NULL DEFAULT 'FREE',
    billing_type VARCHAR(20) NOT NULL DEFAULT 'POSTPAID',
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',

    -- III. DỮ LIỆU ĐỘNG (JSONB)
    profile JSONB NOT NULL DEFAULT '{}',
    settings JSONB NOT NULL DEFAULT '{}',

    -- IV. TRẠNG THÁI & TRUY VẾT
    status VARCHAR(20) NOT NULL DEFAULT 'TRIAL',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT uq_tenants_code UNIQUE (code),
    CONSTRAINT chk_tenants_code_fmt CHECK (code ~ '^[a-z0-9-]+$'),
    CONSTRAINT chk_tenants_tier
CHECK (tier IN (
    'FREE', 'PRO', 'ENTERPRISE', -- Khách hàng cuối
    'PARTNER_BASIC', 'PARTNER_PREMIUM', 'PARTNER_ELITE', -- Đối tác
    'PROVIDER' -- Chủ nền tảng
)),
    CONSTRAINT fk_tenants_parent FOREIGN KEY (parent_tenant_id) REFERENCES tenants(_id),
    CONSTRAINT chk_tenants_status CHECK (status IN ('TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED')),
    CONSTRAINT chk_tenants_region CHECK (data_region IN ('ap-southeast-1', 'us-east-1', 'eu-central-1')),
    CONSTRAINT chk_tenants_compliance CHECK (compliance_level IN ('STANDARD', 'GDPR', 'HIPAA', 'PCI-DSS')),
    CONSTRAINT chk_tenants_billing CHECK (billing_type IN ('PREPAID', 'POSTPAID')),
    CONSTRAINT chk_tenants_updated CHECK (updated_at >= created_at),
    CONSTRAINT chk_tenants_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ xác thực và điều hướng (Login/Routing) theo subdomain/slug
CREATE UNIQUE INDEX idx_tenants_code_active
ON tenants (code)
WHERE deleted_at IS NULL;

-- Index GIN hỗ trợ tìm kiếm linh hoạt bên trong cấu hình Settings (Ví dụ: tìm tenant bắt buộc MFA)
CREATE INDEX idx_tenants_settings_gin
ON tenants USING GIN (settings);

-- Index GIN hỗ trợ tìm kiếm trong Profile (Ví dụ: tìm theo Mã số thuế trong JSON)
CREATE INDEX idx_tenants_profile_gin
ON tenants USING GIN (profile);

-- Index hỗ trợ báo cáo quản trị hệ thống theo khu vực và gói cước
CREATE INDEX idx_tenants_infra_stats
ON tenants (data_region, tier, status);
-- Index hỗ trợ truy vấn cấu trúc cây đối tác phân phối (Materialized Path) [12, 13]
CREATE INDEX idx_tenants_path ON tenants (path ASC) WHERE deleted_at IS NULL;

CREATE TABLE users (
    -- I. ĐỊNH DANH (IDENTITY)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application [3]
    email VARCHAR(255) NOT NULL,
    password_hash TEXT, -- Lưu chuỗi hash Argon2id [8]
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    phone_number VARCHAR(20),

    -- II. TRẠNG THÁI & BẢO MẬT (SECURITY)
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_support_staff BOOLEAN NOT NULL DEFAULT FALSE, -- Phục vụ Impersonation [12]
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret TEXT, -- Cần mã hóa ở tầng ứng dụng trước khi lưu
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,

    -- III. CẤU HÌNH & THÔNG TIN THÊM
    locale VARCHAR(10) NOT NULL DEFAULT 'vi-VN',
    metadata JSONB NOT NULL DEFAULT '{}',

    -- IV. TRUY VẾT (AUDIT)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT uq_users_phone UNIQUE (phone_number),
    CONSTRAINT chk_users_email_fmt CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_url_fmt CHECK (avatar_url IS NULL OR avatar_url ~* '^https?://'),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'BANNED', 'DISABLED', 'PENDING')),
    CONSTRAINT chk_users_updated CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index duy nhất cho Email (Hỗ trợ Soft Delete)
-- Chỉ check trùng với các user chưa bị xóa (deleted_at IS NULL) [16]
CREATE UNIQUE INDEX idx_users_email_active
ON users (email)
WHERE deleted_at IS NULL;

-- Index tìm kiếm mờ (Fuzzy Search) bằng Trigram
-- Hỗ trợ tìm user theo tên hoặc email kể cả khi gõ sai chính tả [17]
-- Cần bật extension: CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_users_search_trgm
ON users USING GIN (email gin_trgm_ops);
CREATE INDEX idx_users_search_trgm
ON users USING GIN (full_name gin_trgm_ops);

-- Index hỗ trợ quản trị viên lọc user theo trạng thái và thời gian tạo [18]
CREATE INDEX idx_users_status_created
ON users (status, created_at DESC);


CREATE TABLE tenant_members (
    -- I. ĐỊNH DANH & LIÊN KẾT (IDENTITY & LINK)
    _id UUID PRIMARY KEY, -- Khuyến nghị gen UUID v7 từ Application
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,

    -- II. THÔNG TIN VẬN HÀNH (OPERATIONAL)
    display_name VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'INVITED',
    custom_data JSONB NOT NULL DEFAULT '{}',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- III. TRUY VẾT & PHIÊN BẢN (AUDIT & VERSIONING)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID,
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_mem_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_mem_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    -- Đảm bảo một User chỉ có duy nhất 1 hồ sơ tại 1 Tenant (không trùng lặp)
    CONSTRAINT uq_tenant_user UNIQUE (tenant_id, user_id),
    CONSTRAINT chk_mem_status CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'RESIGNED')),
    CONSTRAINT chk_mem_updated CHECK (updated_at >= created_at)
);

-- Index quan trọng để truy vấn danh sách thành viên của một Tenant nhanh hơn
CREATE INDEX idx_mem_tenant ON tenant_members (tenant_id) WHERE deleted_at IS NULL;

-- GIN Index để tìm kiếm trong custom_data (Ví dụ: tìm theo mã nhân viên lưu trong JSON)
CREATE INDEX idx_mem_custom_data ON tenant_members USING GIN (custom_data);


CREATE TABLE departments (
    -- I. ĐỊNH DANH & PHÂN CẤP (IDENTITY & HIERARCHY)
    _id UUID PRIMARY KEY, -- Khuyến nghị gen UUID v7 từ Application
    tenant_id UUID NOT NULL,
    parent_id UUID,

    -- II. THÔNG TIN NGHIỆP VỤ (BUSINESS DATA)
    name TEXT NOT NULL,
    code VARCHAR(50),
    type VARCHAR(20) NOT NULL DEFAULT 'TEAM',
    head_member_id UUID,
    path TEXT, -- Cấu trúc: /parent_id/child_id/

    -- III. TRUY VẾT & PHIÊN BẢN (AUDIT & VERSIONING)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_dept_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_parent FOREIGN KEY (parent_id) REFERENCES departments(_id),
    CONSTRAINT chk_dept_status CHECK (type IN ('DIVISION', 'DEPARTMENT', 'TEAM')),
    CONSTRAINT chk_dept_updated CHECK (updated_at >= created_at)
);

-- Index để tìm tất cả phòng ban con cực nhanh bằng toán tử LIKE hoặc mẫu text [8], [3]
CREATE INDEX idx_dept_path ON departments (tenant_id, path text_pattern_ops) WHERE deleted_at IS NULL;

-- Index hỗ trợ tìm kiếm phòng ban theo Tenant (SaaS isolation) [6], [13]
CREATE INDEX idx_dept_tenant ON departments (tenant_id) WHERE deleted_at IS NULL;

CREATE TABLE department_members (
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    department_id UUID NOT NULL,
    member_id UUID NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    role_in_dept VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ràng buộc tham chiếu
    CONSTRAINT fk_dept_mem_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_mem_dept FOREIGN KEY (department_id) REFERENCES departments(_id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_mem_member FOREIGN KEY (member_id) REFERENCES tenant_members(_id) ON DELETE CASCADE,

    -- Đảm bảo một nhân sự không bị gán trùng lặp vào cùng một phòng ban
    CONSTRAINT uq_dept_member_unique UNIQUE (tenant_id, department_id, member_id),
    CONSTRAINT chk_dept_mem_updated CHECK (updated_at >= created_at)
);

-- 2. TẠO CÁC INDEX CHIẾN LƯỢC

-- Index hỗ trợ truy vấn danh sách nhân viên của một phòng ban cụ thể
CREATE INDEX idx_dept_mem_lookup
ON department_members (tenant_id, department_id);

-- Index hỗ trợ tìm tất cả các phòng ban mà một nhân viên đang tham gia
CREATE INDEX idx_dept_mem_member
ON department_members (tenant_id, member_id);

-- Index lọc nhanh những nhân sự thuộc phòng ban chính (dùng cho báo cáo nhân sự)
CREATE INDEX idx_dept_mem_primary
ON department_members (tenant_id, is_primary)
WHERE is_primary = TRUE;


CREATE TABLE user_groups (
    -- I. ĐỊNH DANH & PHÂN CẤP
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    parent_id UUID,

    -- II. THÔNG TIN NGHIỆP VỤ
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50),
    type VARCHAR(20) NOT NULL DEFAULT 'CUSTOM',
    dynamic_rules JSONB,
    path TEXT,
    description TEXT,
    owner_member_id UUID,

    -- III. TRUY VẾT & PHIÊN BẢN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC
    CONSTRAINT fk_groups_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_groups_parent FOREIGN KEY (parent_id) REFERENCES user_groups(_id),
    CONSTRAINT fk_groups_owner FOREIGN KEY (owner_member_id) REFERENCES tenant_members(_id),
    CONSTRAINT uq_group_tenant_code UNIQUE (tenant_id, code), -- Mã nhóm là duy nhất trong một công ty
    CONSTRAINT chk_groups_type CHECK (type IN ('ORG_UNIT', 'PROJECT', 'PERMISSION', 'CUSTOM'))
);

-- 2. Tạo các Index chiến lược

-- Index hỗ trợ phân tách dữ liệu đa tenant (Bắt buộc cho SaaS) [8]
CREATE INDEX idx_groups_tenant ON user_groups (tenant_id);

-- Index hỗ trợ truy vấn cấu trúc cây (Hierarchy) bằng Materialized Path [9]
-- Sử dụng text_pattern_ops để tối ưu cho toán tử LIKE 'path/%'
CREATE INDEX idx_groups_path ON user_groups (tenant_id, path text_pattern_ops);

-- Index hỗ trợ tìm kiếm nhanh theo loại nhóm
CREATE INDEX idx_groups_type ON user_groups (tenant_id, type);


CREATE TABLE group_members (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    group_id UUID NOT NULL,
    member_id UUID NOT NULL,

    -- II. THÔNG TIN NGHIỆP VỤ
    role_in_group VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- III. TRUY VẾT & PHIÊN BẢN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_gm_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_gm_group FOREIGN KEY (group_id) REFERENCES user_groups(_id) ON DELETE CASCADE,
    CONSTRAINT fk_gm_member FOREIGN KEY (member_id) REFERENCES tenant_members(_id) ON DELETE CASCADE,

    -- Đảm bảo một thành viên không bị gán trùng lặp vào cùng một nhóm
    CONSTRAINT uq_group_member UNIQUE (group_id, member_id),

    CONSTRAINT chk_gm_role CHECK (role_in_group IN ('LEADER', 'MEMBER', 'SECRETARY')),
    CONSTRAINT chk_gm_version CHECK (version >= 1)
);

-- 2. CÁC CHỈ MỤC CHIẾN LƯỢC (INDEXES)

-- Index hỗ trợ truy vấn nhanh danh sách tất cả thành viên của một nhóm (Access Pattern: View Group)
CREATE INDEX idx_gm_lookup_group
ON group_members (tenant_id, group_id);

-- Index hỗ trợ tìm tất cả các nhóm mà một nhân sự đang tham gia (Access Pattern: User Profile)
CREATE INDEX idx_gm_lookup_member
ON group_members (tenant_id, member_id);

CREATE TABLE location_types (
    -- I. ĐỊNH DANH & PHÂN QUYỀN DỮ LIỆU
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID,       -- NULL = System Type, NOT NULL = Custom Type

    -- II. THÔNG TIN NGHIỆP VỤ
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,

    -- III. CẤU HÌNH ĐỘNG (CORE FEATURE)
    -- Lưu cấu trúc schema cho các trường bổ sung
    extra_fields JSONB NOT NULL DEFAULT '[]',

    -- IV. TRẠNG THÁI VẬN HÀNH
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- V. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_loctype_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,

    -- Mã code phải viết hoa, không dấu cách
    CONSTRAINT chk_loctype_code_fmt CHECK (code ~ '^[A-Z0-9_]+$'),

    CONSTRAINT chk_loctype_name_len CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_loctype_version CHECK (version >= 1),
    CONSTRAINT chk_loctype_dates CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- A. Đảm bảo tính duy nhất của Code cho từng Tenant (Custom Types)
CREATE UNIQUE INDEX idx_loctype_tenant_code
ON location_types (tenant_id, code)
WHERE tenant_id IS NOT NULL;

-- B. Đảm bảo tính duy nhất của Code cho hệ thống (System Types)
CREATE UNIQUE INDEX idx_loctype_system_code
ON location_types (code)
WHERE tenant_id IS NULL;

-- C. Index hỗ trợ load danh sách loại địa điểm cho Tenant
-- (Bao gồm cả loại của Tenant đó VÀ loại của Hệ thống)
CREATE INDEX idx_loctype_lookup
ON location_types (tenant_id, is_active)
WHERE is_active = TRUE;

-- D. Index GIN để tìm kiếm/validate trong cấu hình trường động
CREATE INDEX idx_loctype_extra_fields
ON location_types USING GIN (extra_fields);

CREATE TABLE locations (
    -- I. ĐỊNH DANH & CẤU TRÚC (Identity & Structure)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    parent_id UUID,
    type_id UUID NOT NULL, -- Link tới bảng location_types

    -- II. THÔNG TIN CƠ BẢN (Basic Info)
    name TEXT NOT NULL,
    code VARCHAR(50),
    path TEXT, -- Materialized Path: /root_id/parent_id/this_id/
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- III. ĐỊA LÝ & CHẤM CÔNG (Geo & Timekeeping)
    address JSONB NOT NULL DEFAULT '{}',
    coordinates POINT, -- Lưu (Long, Lat)
    radius_meters INT DEFAULT 100,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC', -- Mặc định UTC, App sẽ override
    is_headquarter BOOLEAN NOT NULL DEFAULT FALSE,

    -- IV. DỮ LIỆU ĐỘNG (EAV over JSONB)
    metadata JSONB NOT NULL DEFAULT '{}',

    -- V. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft Delete
    version BIGINT NOT NULL DEFAULT 1,

    -- CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_loc_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_loc_parent FOREIGN KEY (parent_id) REFERENCES locations(_id),
    CONSTRAINT fk_loc_type FOREIGN KEY (type_id) REFERENCES location_types(_id),

    CONSTRAINT uq_loc_code UNIQUE (tenant_id, code), -- Mã địa điểm duy nhất trong 1 Tenant
    CONSTRAINT chk_loc_name CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_loc_radius CHECK (radius_meters > 0),
    CONSTRAINT chk_loc_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED')),
    CONSTRAINT chk_loc_dates CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh danh sách địa điểm của một Tenant
CREATE INDEX idx_locations_tenant
ON locations (tenant_id, status)
WHERE deleted_at IS NULL;

-- Index "Thần thánh" cho cây phân cấp (Materialized Path)
-- Giúp query: Lấy tất cả phòng ban con của Chi nhánh A (WHERE path LIKE '/A/%')
CREATE INDEX idx_locations_path
ON locations (tenant_id, path text_pattern_ops)
WHERE deleted_at IS NULL;

-- Index GIN hỗ trợ tìm kiếm sâu trong dữ liệu động (Metadata)
-- VD: Tìm tất cả kho hàng có diện tích > 500m2 (lưu trong metadata)
CREATE INDEX idx_locations_metadata
ON locations USING GIN (metadata);

-- Index hỗ trợ tìm kiếm trụ sở chính
CREATE INDEX idx_locations_hq
ON locations (tenant_id)
WHERE is_headquarter = TRUE AND deleted_at IS NULL;

-- (Tùy chọn) Index không gian để tìm địa điểm gần nhất (Nếu dùng tính năng chấm công GPS)
-- Cần cài extension: CREATE EXTENSION IF NOT EXISTS postgis; (Nếu dùng PostGIS)
-- Hoặc dùng Index mặc định của Yugabyte cho Point
CREATE INDEX idx_locations_geo ON locations USING GIST (coordinates);


CREATE TABLE user_linked_identities (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application [4]
    user_id UUID NOT NULL,

    -- II. THÔNG TIN XÁC THỰC
    provider VARCHAR(20) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    password_hash TEXT, -- TEXT tối ưu hơn VARCHAR cho các thuật toán băm hiện đại [7]

    -- III. DỮ LIỆU ĐỘNG & TRUY VẾT
    data JSONB NOT NULL DEFAULT '{}',
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_identity_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    -- Đảm bảo 1 tài khoản mạng xã hội chỉ gắn với 1 user duy nhất trên hệ thống [6]
    CONSTRAINT uq_provider_identity UNIQUE (provider, provider_id),
    -- Kiểm soát danh sách các nhà cung cấp được phép
    CONSTRAINT chk_identity_provider CHECK (provider IN ('LOCAL', 'GOOGLE', 'GITHUB', 'MICROSOFT', 'APPLE', 'PASSKEY'))
);

-- 2. CÁC CHỈ MỤC CHIẾN LƯỢC (INDEXES)

-- Index quan trọng nhất: Tìm nhanh User ID khi đăng nhập qua Google/Github/Email [8]
-- Query: SELECT user_id FROM user_linked_identities WHERE provider = 'GOOGLE' AND provider_id = '...';
CREATE INDEX idx_identity_lookup
ON user_linked_identities (provider, provider_id);

-- Index hỗ trợ trang quản lý tài khoản: Hiển thị các phương thức đã liên kết của 1 user
CREATE INDEX idx_identity_user_id
ON user_linked_identities (user_id);


CREATE TABLE user_sessions (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application [3]
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,

    -- II. CƠ CHẾ XOAY VÒNG (ROTATION) & BẢO MẬT [2]
    family_id UUID NOT NULL,
    refresh_token_hash VARCHAR(255),
    rotation_counter INT NOT NULL DEFAULT 0,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,

    -- III. THÔNG TIN THIẾT BỊ & VỊ TRÍ [4]
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(20),
    os_name VARCHAR(50),
    browser_name VARCHAR(50),
    location_city VARCHAR(100),
    location_country VARCHAR(50),

    -- IV. THỜI GIAN [7]
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,

    -- V. RÀNG BUỘC
    CONSTRAINT fk_sessions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT chk_rotation_val CHECK (rotation_counter >= 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh danh sách thiết bị đang hoạt động của người dùng [7]
CREATE INDEX idx_sessions_user_active
ON user_sessions (user_id)
WHERE is_revoked = FALSE;

-- Index hỗ trợ quét các phiên đã hết hạn để dọn dẹp (Cleanup Job)
CREATE INDEX idx_sessions_expiry
ON user_sessions (expires_at)
WHERE is_revoked = FALSE;

-- Index hỗ trợ kiểm tra nhanh token trong cùng một family khi thực hiện rotation [6]
CREATE INDEX idx_sessions_family
ON user_sessions (family_id);


CREATE TABLE user_mfa_methods (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application để tránh Hotspot [3, 5]
    user_id UUID NOT NULL,

    -- II. CHI TIẾT PHƯƠNG THỨC
    type VARCHAR(20) NOT NULL,
    name VARCHAR(50),
    encrypted_secret TEXT NOT NULL, -- Sử dụng TEXT để linh hoạt cho các loại secret khác nhau [6]
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    -- III. TRUY VẾT (AUDIT)
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_mfa_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT chk_mfa_type CHECK (type IN ('TOTP', 'SMS', 'EMAIL', 'HARDWARE')),
    CONSTRAINT chk_mfa_timeline CHECK (last_used_at IS NULL OR last_used_at >= created_at)
);

-- 2. CÁC CHỈ MỤC CHIẾN LƯỢC (INDEXES)

-- Index hỗ trợ tìm nhanh các phương thức MFA của một người dùng khi đăng nhập
CREATE INDEX idx_user_mfa_lookup
ON user_mfa_methods (user_id);

-- Index một phần (Partial Index) để xác định nhanh phương thức mặc định của người dùng
CREATE INDEX idx_user_mfa_default
ON user_mfa_methods (user_id)
WHERE is_default = TRUE;

CREATE TABLE user_webauthn_credentials (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application [3]
    user_id UUID NOT NULL,

    -- II. DỮ LIỆU KỸ THUẬT FIDO2/PASSKEY
    name VARCHAR(100),
    credential_id TEXT NOT NULL,
    public_key TEXT NOT NULL,
    sign_count INT NOT NULL DEFAULT 0,
    transports TEXT[], -- Kiểu mảng hỗ trợ bởi YSQL/Postgres [2]

    -- III. TRUY VẾT THỜI GIAN
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_webauthn_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT uq_credential_id UNIQUE (credential_id), -- Credential ID phải là duy nhất toàn sàn [1]
    CONSTRAINT chk_sign_count CHECK (sign_count >= 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng: Tìm nhanh toàn bộ thiết bị Passkey của một người dùng khi bắt đầu bước Login Challenge
CREATE INDEX idx_webauthn_user_lookup
ON user_webauthn_credentials (user_id);

-- Index hỗ trợ việc xác thực dựa trên Credential ID trả về từ trình duyệt
CREATE INDEX idx_webauthn_credential_lookup
ON user_webauthn_credentials (credential_id);


CREATE TABLE user_backup_codes (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    user_id UUID NOT NULL,

    -- II. NỘI DUNG & TRẠNG THÁI
    code_hash TEXT NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,

    -- III. TRUY VẾT THỜI GIAN
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    -- Xóa người dùng sẽ tự động xóa các mã dự phòng liên quan (GDPR Compliance)
    CONSTRAINT fk_backup_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,

    -- Đảm bảo logic thời gian: Ngày sử dụng phải sau ngày tạo
    CONSTRAINT chk_backup_time CHECK (used_at IS NULL OR used_at >= created_at)
);

-- 2. CÁC CHỈ MỤC CHIẾN LƯỢC (INDEXES)

-- Index hỗ trợ tìm nhanh danh sách các mã dự phòng của một người dùng cụ thể
CREATE INDEX idx_backup_user_lookup
ON user_backup_codes (user_id);

-- Partial Index: Chỉ index các mã chưa sử dụng để tăng tốc độ xác thực khi login
-- Giảm dung lượng index và tăng hiệu năng do không chứa các mã đã dùng
CREATE INDEX idx_backup_unused_codes
ON user_backup_codes (user_id)
WHERE is_used = FALSE;


CREATE TABLE tenant_sso_configs (
    -- I. ĐỊNH DANH & LIÊN KẾT
    tenant_id UUID PRIMARY KEY, -- Sử dụng luôn tenant_id làm PK vì quan hệ 1-1

    -- II. THÔNG TIN KỸ THUẬT IdP
    provider_type VARCHAR(20) NOT NULL,
    entry_point_url TEXT NOT NULL,
    issuer_id TEXT,
    cert_public_key TEXT,
    client_id VARCHAR(255),
    client_secret_enc TEXT,

    -- III. CẤU HÌNH NGHIỆP VỤ
    attribute_mapping JSONB NOT NULL DEFAULT '{}',
    is_enforced BOOLEAN NOT NULL DEFAULT FALSE,

    -- IV. TRUY VẾT & PHIÊN BẢN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_sso_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_sso_provider CHECK (provider_type IN ('AZURE_AD', 'OKTA', 'GOOGLE', 'SAML', 'OIDC')),
    CONSTRAINT chk_sso_dates CHECK (updated_at >= created_at),
    CONSTRAINT chk_sso_version CHECK (version >= 1)
);

-- 2. CÁC CHỈ MỤC CHIẾN LƯỢC (INDEXES)

-- Mặc dù tenant_id đã là PRIMARY KEY (có sẵn index),
-- chúng ta có thể tạo thêm index trên is_enforced để hệ thống quản trị
-- nhanh chóng lọc ra các Tenant đang áp dụng chính sách bảo mật nghiêm ngặt.
CREATE INDEX idx_sso_enforced ON tenant_sso_configs (is_enforced) WHERE is_enforced = TRUE;

-- Index hỗ trợ tìm kiếm cấu hình theo loại nhà cung cấp
CREATE INDEX idx_sso_provider ON tenant_sso_configs (provider_type);



CREATE TABLE auth_verification_codes (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. NỘI DUNG & LOẠI XÁC THỰC
    identifier VARCHAR(255) NOT NULL,
    type VARCHAR(30) NOT NULL,
    code_hash TEXT NOT NULL,

    -- III. KIỂM SOÁT THỜI GIAN & BẢO MẬT
    expires_at TIMESTAMPTZ NOT NULL,
    attempt_count INT NOT NULL DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_auth_codes_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_auth_codes_type CHECK (type IN ('EMAIL_VERIFICATION', 'PASSWORD_RESET', 'LOGIN_OTP', 'MAGIC_LINK')),
    CONSTRAINT chk_auth_codes_attempts CHECK (attempt_count <= 5),
    CONSTRAINT chk_auth_codes_expiry CHECK (expires_at > created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh mã hợp lệ gần nhất cho một User/Email/Phone cụ thể
-- Giúp tăng tốc luồng verify OTP khi user nhập mã
CREATE INDEX idx_auth_codes_lookup
ON auth_verification_codes (tenant_id, identifier, type, expires_at DESC);

-- Index hỗ trợ dọn dẹp các mã đã hết hạn (Cleanup Job)
-- Sử dụng Partial Index để chỉ tập trung vào các bản ghi đã quá hạn
CREATE INDEX idx_auth_codes_cleanup
ON auth_verification_codes (expires_at)
WHERE expires_at < NOW();


CREATE TABLE personal_access_tokens (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,

    -- II. THÔNG TIN TOKEN & BẢO MẬT
    name TEXT NOT NULL,
    token_prefix VARCHAR(10) NOT NULL,
    token_hash TEXT NOT NULL,
    scopes TEXT[] NOT NULL, -- Kiểu mảng hỗ trợ phân quyền linh hoạt

    -- III. TRẠNG THÁI & THỜI GIAN
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_pat_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_pat_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT uq_token_hash UNIQUE (token_hash),
    CONSTRAINT chk_pat_name CHECK (LENGTH(name) > 0)
);

-- 2. Chiến lược đánh Index (Indexing Strategy)

-- Index hỗ trợ xác thực token cực nhanh khi có request API
-- Truy vấn: SELECT user_id, scopes FROM personal_access_tokens WHERE token_hash = ? AND is_active = TRUE;
CREATE INDEX idx_pat_auth_lookup
ON personal_access_tokens (token_hash)
WHERE is_active = TRUE;

-- Index hỗ trợ trang quản lý: Hiển thị danh sách token của một người dùng trong một Tenant
CREATE INDEX idx_pat_user_list
ON personal_access_tokens (tenant_id, user_id);

-- Index hỗ trợ các tác vụ dọn dẹp (Cleanup) token đã hết hạn
CREATE INDEX idx_pat_expiry
ON personal_access_tokens (expires_at)
WHERE expires_at IS NOT NULL;


CREATE TABLE roles (
    -- I. ĐỊNH DANH & PHÂN TÁCH (IDENTITY & SHARDING)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN NGHIỆP VỤ
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL DEFAULT 'CUSTOM',

    -- III. QUYỀN HẠN (Sử dụng mảng TEXT[] để tối ưu hiệu năng)
    permission_codes TEXT[] NOT NULL DEFAULT '{}',

    -- IV. TRUY VẾT & PHIÊN BẢN (AUDIT & VERSIONING)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_role_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_role_type CHECK (type IN ('SYSTEM', 'CUSTOM')),
    CONSTRAINT chk_role_version CHECK (version >= 1),
    CONSTRAINT chk_role_dates CHECK (updated_at >= created_at),
    -- Đảm bảo tên vai trò là duy nhất trong phạm vi một Tenant
    CONSTRAINT uq_role_name_per_tenant UNIQUE (tenant_id, name)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy nhanh danh sách vai trò của một Tenant
CREATE INDEX idx_roles_tenant_lookup
ON roles (tenant_id);

-- Index GIN hỗ trợ tìm kiếm các vai trò có chứa một mã quyền cụ thể
-- Query: SELECT * FROM roles WHERE 'user:view' = ANY(permission_codes);
CREATE INDEX idx_roles_permissions
ON roles USING GIN (permission_codes);


CREATE TABLE permissions (
    -- I. Định danh & Liên kết kỹ thuật
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    app_code VARCHAR(50) NOT NULL,
    code VARCHAR(100) NOT NULL,
    parent_code VARCHAR(100),

    -- II. Cấu trúc cây & Phân nhóm
    path TEXT, -- Cấu trúc lưu trữ: /root_code/parent_code/this_code/
    is_group BOOLEAN NOT NULL DEFAULT FALSE,

    -- III. Thông tin hiển thị
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- IV. Audit Mixins
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- V. Ràng buộc toàn vẹn
    CONSTRAINT fk_perm_app FOREIGN KEY (app_code) REFERENCES applications(code),
    CONSTRAINT fk_perm_parent FOREIGN KEY (parent_code) REFERENCES permissions(code),
    CONSTRAINT uq_permissions_code UNIQUE (code),
    CONSTRAINT chk_perm_updated CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh mã quyền khi kiểm tra Entitlement (AuthZ)
CREATE UNIQUE INDEX idx_permissions_code_lookup
ON permissions (code);

-- Index hỗ trợ lọc danh sách quyền theo từng ứng dụng
CREATE INDEX idx_permissions_app_filter
ON permissions (app_code);

-- Index "thần thánh" hỗ trợ truy vấn cấu trúc cây (Materialized Path)
-- Giúp query: WHERE path LIKE '/HRM/%' đạt hiệu năng O(log N)
CREATE INDEX idx_permissions_path_tree
ON permissions (path text_pattern_ops);

-- Comment để hỗ trợ Documentation
COMMENT ON TABLE permissions IS 'Danh mục quyền hạn hệ thống hỗ trợ phân cấp nhiều tầng';


CREATE TABLE user_roles (
    -- I. ĐỊNH DANH & LIÊN KẾT (IDENTITY & LINKING)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    member_id UUID NOT NULL,
    role_id UUID NOT NULL,

    -- II. PHẠM VI DỮ LIỆU (DATA SCOPING)
    scope_type VARCHAR(50) NOT NULL DEFAULT 'GLOBAL',
    scope_values TEXT[] NOT NULL DEFAULT '{}',

    -- III. TRUY VẾT (AUDIT)
    assigned_by UUID,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_ur_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_member FOREIGN KEY (member_id) REFERENCES tenant_members(_id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(_id) ON DELETE CASCADE,

    -- Đảm bảo không gán trùng lặp 1 Role với cùng 1 Scope cho 1 người
    CONSTRAINT uq_member_role_scope UNIQUE (member_id, role_id, scope_type),

    -- Kiểm tra giá trị hợp lệ cho scope_type
    CONSTRAINT chk_ur_scope_type CHECK (scope_type IN ('GLOBAL', 'DEPARTMENT', 'LOCATION', 'PROJECT'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: Lấy toàn bộ Role và Scope của nhân viên khi đăng nhập để tính toán quyền (Flattening)
CREATE INDEX idx_ur_member_lookup
ON user_roles (member_id, tenant_id);

-- Index hỗ trợ tìm kiếm: "Ai là Manager của Department X?"
CREATE INDEX idx_ur_scope_search
ON user_roles USING GIN (scope_values)
WHERE scope_type = 'DEPARTMENT';


CREATE TABLE relationship_tuples (
    tenant_id UUID NOT NULL,

    -- THÔNG TIN TÀI NGUYÊN (OBJECT)
    namespace VARCHAR(50) NOT NULL,
    object_id UUID NOT NULL,

    -- MỐI QUAN HỆ (RELATION)
    relation VARCHAR(50) NOT NULL,

    -- ĐỐI TƯỢNG NHẬN QUYỀN (SUBJECT)
    subject_namespace VARCHAR(50) NOT NULL,
    subject_id UUID NOT NULL,
    subject_relation VARCHAR(50),

    -- THỜI GIAN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_tuples_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,

    -- Khóa chính phức hợp tối ưu cho việc truy vấn từ Object sang Subject
    PRIMARY KEY (tenant_id, namespace, object_id, relation, subject_namespace, subject_id)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index đảo ngược (Reverse Lookup Index)
-- Hỗ trợ trả lời cực nhanh câu hỏi: "Người dùng A có quyền xem những tài liệu nào?"
CREATE INDEX idx_tuples_reverse_lookup
ON relationship_tuples (tenant_id, subject_id, relation, namespace);

-- Index hỗ trợ kiểm tra quyền theo loại tài nguyên (Namespace)
CREATE INDEX idx_tuples_namespace_lookup
ON relationship_tuples (tenant_id, namespace, relation);


CREATE TABLE access_control_lists (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN TÀI NGUYÊN (RESOURCE)
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID NOT NULL,

    -- III. THÔNG TIN ĐỐI TƯỢNG (SUBJECT)
    subject_type VARCHAR(20) NOT NULL,
    subject_id UUID NOT NULL,

    -- IV. QUYỀN HẠN
    action VARCHAR(50) NOT NULL,
    is_allowed BOOLEAN NOT NULL DEFAULT TRUE,

    -- V. TRUY VẾT
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- VI. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_acl_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_acl_entry UNIQUE (tenant_id, resource_type, resource_id, subject_type, subject_id, action),
    CONSTRAINT chk_acl_subject_type CHECK (subject_type IN ('MEMBER', 'GROUP', 'ROLE')),
    CONSTRAINT chk_acl_action CHECK (action IN ('READ', 'WRITE', 'DELETE', 'SHARE'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ kiểm tra quyền của một Member đối với một tài nguyên cụ thể (AuthZ Check)
CREATE INDEX idx_acl_lookup
ON access_control_lists (tenant_id, resource_id, subject_id);

-- Index hỗ trợ việc lấy danh sách tất cả các tài nguyên mà một Member/Group có quyền truy cập
CREATE INDEX idx_acl_subject_search
ON access_control_lists (tenant_id, subject_id, subject_type);

CREATE TABLE tenant_domains (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN TÊN MIỀN
    domain VARCHAR(255) NOT NULL,

    -- III. QUY TRÌNH XÁC THỰC
    verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verification_method VARCHAR(20),
    verification_token VARCHAR(100),

    -- IV. CHÍNH SÁCH HÀNH VI
    policy VARCHAR(20) NOT NULL DEFAULT 'NONE',

    -- V. TRUY VẾT THỜI GIAN
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- VI. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_domain_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_tenant_domain_name UNIQUE (domain), -- Một domain chỉ thuộc về 1 Tenant duy nhất
    CONSTRAINT chk_domain_status CHECK (verification_status IN ('PENDING', 'VERIFIED')),
    CONSTRAINT chk_domain_method CHECK (verification_method IN ('DNS_TXT', 'HTML_FILE')),
    CONSTRAINT chk_domain_policy CHECK (policy IN ('NONE', 'CAPTURE', 'ENFORCE_SSO')),
    CONSTRAINT chk_domain_fmt CHECK (domain ~ '^[a-z0-9.-]+$') -- Chỉ cho phép chữ thường, số, dấu chấm và gạch ngang
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh Tenant sở hữu một tên miền khi User đăng ký hoặc đăng nhập
CREATE UNIQUE INDEX idx_tenant_domain_lookup
ON tenant_domains (domain)
WHERE verification_status = 'VERIFIED';

-- Index hỗ trợ việc quản lý danh sách domain của một Tenant cụ thể
CREATE INDEX idx_tenant_domain_list
ON tenant_domains (tenant_id);


CREATE TABLE tenant_invitations (
    -- I. ĐỊNH DANH & LIÊN KẾT (IDENTITY & LINKING)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application [3]
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN NGƯỜI NHẬN & VAI TRÒ
    email VARCHAR(255) NOT NULL,
    role_ids TEXT[] DEFAULT '{}',
    department_id UUID,

    -- III. KIỂM SOÁT XÁC THỰC & TRẠNG THÁI
    token VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMPTZ NOT NULL,

    -- IV. TRUY VẾT (AUDIT)
    invited_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_invitation_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_invitation_token UNIQUE (token),
    CONSTRAINT chk_invitation_status CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')),
    CONSTRAINT chk_invitation_email_fmt CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT chk_invitation_expiry CHECK (expires_at > created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh khi người dùng click vào link mời (Token Lookup)
CREATE UNIQUE INDEX idx_invitation_token_lookup
ON tenant_invitations (token)
WHERE status = 'PENDING';

-- Index hỗ trợ Admin quản lý danh sách lời mời của một Tenant (Theo dõi tiến độ Onboarding)
CREATE INDEX idx_invitation_tenant_list
ON tenant_invitations (tenant_id, created_at DESC);

-- Index hỗ trợ Job dọn dẹp hoặc tự động cập nhật trạng thái hết hạn
CREATE INDEX idx_invitation_expiry_cleanup
ON tenant_invitations (expires_at)
WHERE status = 'PENDING' AND expires_at < NOW();


CREATE TABLE access_reviews (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application để tối ưu hiệu năng ghi
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN NGHIỆP VỤ
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    -- III. KIỂM SOÁT THỜI GIAN & PHIÊN BẢN
    deadline TIMESTAMPTZ NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_access_review_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_access_review_creator FOREIGN KEY (created_by) REFERENCES users(_id),
    CONSTRAINT chk_review_status CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_review_dates CHECK (updated_at >= created_at),
    CONSTRAINT chk_review_version CHECK (version >= 1),
    CONSTRAINT chk_review_name_len CHECK (LENGTH(name) > 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm các đợt rà soát của một Tenant (Sắp xếp theo thời gian mới nhất)
CREATE INDEX idx_access_reviews_tenant_lookup
ON access_reviews (tenant_id, created_at DESC);

-- Index hỗ trợ hệ thống quản trị theo dõi các đợt rà soát sắp đến hạn
-- Giúp chạy các Background Jobs gửi thông báo nhắc nhở (Reminder)
CREATE INDEX idx_access_reviews_deadline
ON access_reviews (status, deadline)
WHERE status IN ('PENDING', 'IN_PROGRESS');


CREATE TABLE access_review_items (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    review_id UUID NOT NULL,
    reviewer_id UUID NOT NULL,
    target_member_id UUID NOT NULL,
    role_id UUID NOT NULL,

    -- II. QUYẾT ĐỊNH RÀ SOÁT
    decision VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reason TEXT,
    reviewed_at TIMESTAMPTZ,

    -- III. TRUY VẾT THỜI GIAN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_item_review FOREIGN KEY (review_id) REFERENCES access_reviews(_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_reviewer FOREIGN KEY (reviewer_id) REFERENCES tenant_members(_id),
    CONSTRAINT fk_item_target FOREIGN KEY (target_member_id) REFERENCES tenant_members(_id),
    CONSTRAINT fk_item_role FOREIGN KEY (role_id) REFERENCES roles(_id),
    CONSTRAINT chk_item_decision CHECK (decision IN ('PENDING', 'KEEP', 'REVOKE')),
    CONSTRAINT chk_item_dates CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ trang Dashboard của người rà soát: "Lấy tất cả mục tôi cần xử lý trong đợt này"
CREATE INDEX idx_review_items_reviewer_task
ON access_review_items (reviewer_id, review_id)
WHERE decision = 'PENDING';

-- Index hỗ trợ báo cáo tiến độ: "Có bao nhiêu mục đã hoàn thành trong đợt rà soát X?"
CREATE INDEX idx_review_items_status
ON access_review_items (review_id, decision);

-- Index hỗ trợ lịch sử nhân viên: "Nhân viên A đã từng bị thu hồi những quyền gì trong quá khứ?"
CREATE INDEX idx_review_items_target_history
ON access_review_items (target_member_id)
WHERE decision = 'REVOKE';


CREATE TABLE scim_directories (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. CẤU HÌNH KẾT NỐI
    provider_type VARCHAR(20) NOT NULL,
    scim_token_hash TEXT NOT NULL,

    -- III. TRẠNG THÁI & TRUY VẾT
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_scim_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_scim_token_hash UNIQUE (scim_token_hash),
    CONSTRAINT chk_scim_provider CHECK (provider_type IN ('AZURE_AD', 'OKTA', 'ONELOGIN', 'CUSTOM')),
    CONSTRAINT chk_scim_version CHECK (version >= 1)
);

-- 2. Chiến lược đánh Index (Indexing Strategy)

-- Index hỗ trợ xác thực cực nhanh khi IdP gọi API SCIM (Bearer Token Lookup)
-- Truy vấn: SELECT tenant_id FROM scim_directories WHERE scim_token_hash = ? AND is_active = TRUE;
CREATE INDEX idx_scim_auth_lookup
ON scim_directories (scim_token_hash)
WHERE is_active = TRUE;

-- Index hỗ trợ trang quản trị: Hiển thị danh sách kết nối thư mục của một Tenant
CREATE INDEX idx_scim_tenant_list
ON scim_directories (tenant_id);


CREATE TABLE scim_mappings (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    directory_id UUID NOT NULL,

    -- II. THÔNG TIN ÁNH XẠ (MAPPING DATA)
    external_id VARCHAR(255) NOT NULL,
    internal_entity_type VARCHAR(20) NOT NULL,
    internal_entity_id UUID NOT NULL,

    -- III. TRUY VẾT & ĐỒNG BỘ
    data_hash VARCHAR(64),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_scim_map_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_scim_map_dir FOREIGN KEY (directory_id) REFERENCES scim_directories(_id) ON DELETE CASCADE,
    CONSTRAINT chk_scim_entity_type CHECK (internal_entity_type IN ('USER', 'GROUP')),

    -- Đảm bảo một đối tượng ngoại không bị ánh xạ trùng lặp cho một thư mục
    CONSTRAINT uq_scim_external_lookup UNIQUE (directory_id, external_id, internal_entity_type)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh thực thể nội bộ khi nhận được request từ IdP (Provisioning)
-- Query: SELECT internal_entity_id FROM scim_mappings WHERE directory_id = ? AND external_id = ?;
CREATE UNIQUE INDEX idx_scim_external_sync
ON scim_mappings (directory_id, external_id, internal_entity_type);

-- Index hỗ trợ tìm ngược từ hệ thống nội bộ để gửi update sang IdP (Deprovisioning)
-- Query: SELECT external_id FROM scim_mappings WHERE internal_entity_id = ?;
CREATE INDEX idx_scim_internal_lookup
ON scim_mappings (internal_entity_id);


CREATE TABLE tenant_security_policies (
    -- I. ĐỊNH DANH (IDENTITY)
    -- Sử dụng chính tenant_id làm PK để thực thi quan hệ 1-1 và tối ưu sharding theo Tenant
    tenant_id UUID PRIMARY KEY,

    -- II. CHÍNH SÁCH MẬT KHẨU (PASSWORD POLICY)
    pwd_min_length INT NOT NULL DEFAULT 8,
    pwd_require_special_char BOOLEAN NOT NULL DEFAULT TRUE,
    pwd_expiry_days INT NOT NULL DEFAULT 0,
    pwd_history_limit INT NOT NULL DEFAULT 3,

    -- III. CHÍNH SÁCH PHIÊN & ĐĂNG NHẬP (LOGIN & SESSION)
    session_timeout_minutes INT NOT NULL DEFAULT 1440,
    max_login_attempts INT NOT NULL DEFAULT 5,
    lockout_duration_minutes INT NOT NULL DEFAULT 30,

    -- IV. BẢO MẬT NÂNG CAO (ADVANCED SECURITY)
    mfa_enforced BOOLEAN NOT NULL DEFAULT FALSE,
    allowed_ip_ranges CIDR[], -- Lưu mảng dải IP Whitelist

    -- V. TRUY VẾT (AUDIT)
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- VI. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_policy_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_pwd_len CHECK (pwd_min_length >= 6),
    CONSTRAINT chk_pwd_expiry CHECK (pwd_expiry_days >= 0),
    CONSTRAINT chk_login_attempts CHECK (max_login_attempts > 0),
    CONSTRAINT chk_session_timeout CHECK (session_timeout_minutes > 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)
-- Do tenant_id là PRIMARY KEY, YugabyteDB đã tự động tạo Index B-tree tối ưu.
-- Thêm index cho cập nhật thời gian nếu cần thực hiện các báo cáo tuân thủ (Compliance Audit)
CREATE INDEX idx_security_policies_updated ON tenant_security_policies (updated_at DESC);


CREATE TABLE legal_documents (
    -- I. ĐỊNH DANH & PHIÊN BẢN
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    type VARCHAR(50) NOT NULL,
    version VARCHAR(20) NOT NULL,

    -- II. NỘI DUNG
    title TEXT NOT NULL,
    content_url TEXT NOT NULL,

    -- III. TRẠNG THÁI & THỜI GIAN
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version_locking BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    -- Đảm bảo không trùng lặp phiên bản cho cùng một loại văn bản
    CONSTRAINT uq_doc_type_version UNIQUE (type, version),

    -- Kiểm tra loại văn bản hợp lệ
    CONSTRAINT chk_legal_type CHECK (type IN ('TERMS_OF_SERVICE', 'PRIVACY_POLICY', 'COOKIE_POLICY', 'EULA')),

    -- Kiểm tra định dạng URL cơ bản
    CONSTRAINT chk_legal_url_fmt CHECK (content_url ~* '^https?://')
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy nhanh phiên bản đang hoạt động (Partial Index)
-- Query: SELECT * FROM legal_documents WHERE type = 'TERMS_OF_SERVICE' AND is_active = TRUE;
CREATE UNIQUE INDEX idx_legal_active_version
ON legal_documents (type)
WHERE is_active = TRUE;

-- Index hỗ trợ tra cứu lịch sử thay đổi của một loại văn bản theo thời gian
CREATE INDEX idx_legal_history_lookup
ON legal_documents (type, published_at DESC);


CREATE TABLE user_consents (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application [3]
    user_id UUID NOT NULL,
    document_id UUID NOT NULL,

    -- II. THÔNG TIN XÁC THỰC (EVIDENCE)
    agreed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET NOT NULL,
    user_agent TEXT,

    -- III. QUẢN TRỊ
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_consent_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT fk_consent_doc FOREIGN KEY (document_id) REFERENCES legal_documents(_id),

    -- Đảm bảo mỗi user chỉ đồng ý một lần với một phiên bản tài liệu nhất định [4]
    CONSTRAINT uq_user_document_consent UNIQUE (user_id, document_id),

    CONSTRAINT chk_consent_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ kiểm tra nhanh: "Người dùng này đã đồng ý với phiên bản TOS hiện tại chưa?"
-- Query: SELECT 1 FROM user_consents WHERE user_id = ? AND document_id = ?;
CREATE UNIQUE INDEX idx_consent_lookup
ON user_consents (user_id, document_id);

-- Index hỗ trợ báo cáo tuân thủ và truy vết pháp lý (Audit Trail)
-- Query: SELECT * FROM user_consents WHERE agreed_at BETWEEN ? AND ?;
CREATE INDEX idx_consent_audit_history
ON user_consents (agreed_at DESC);


CREATE TABLE user_delegations (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application [3]
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN ỦY QUYỀN
    delegator_id UUID NOT NULL,
    delegatee_id UUID NOT NULL,

    -- III. PHẠM VI & THỜI GIAN
    scopes TEXT[] NOT NULL DEFAULT '{}',
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,

    -- IV. TRẠNG THÁI & AUDIT
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- V. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_delegation_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_delegator FOREIGN KEY (delegator_id) REFERENCES users(_id),
    CONSTRAINT fk_delegatee FOREIGN KEY (delegatee_id) REFERENCES users(_id),
    CONSTRAINT chk_delegation_expiry CHECK (expires_at > starts_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm nhanh các tài khoản mà người dùng hiện tại có thể "nhập vai" (Switch account)
-- Truy vấn: SELECT delegator_id FROM user_delegations WHERE delegatee_id = ? AND is_active = TRUE AND expires_at > NOW();
CREATE INDEX idx_delegation_lookup_delegatee
ON user_delegations (tenant_id, delegatee_id)
WHERE is_active = TRUE AND expires_at > NOW();

-- Index hỗ trợ người ủy quyền kiểm tra xem mình đã cấp quyền cho những ai
CREATE INDEX idx_delegation_lookup_delegator
ON user_delegations (tenant_id, delegator_id);


CREATE TABLE api_keys (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application layer
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN ĐỊNH DANH (IDENTIFICATION)
    name TEXT NOT NULL,
    key_prefix VARCHAR(10) NOT NULL,
    key_hash TEXT NOT NULL,

    -- III. QUYỀN HẠN & BẢO MẬT (SECURITY)
    scopes TEXT[] NOT NULL DEFAULT '{}',
    allowed_ips CIDR[], -- Kiểu dữ liệu chuyên dụng cho IP/Mạng trong Postgres

    -- IV. TRẠNG THÁI & TRUY VẾT (AUDIT)
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID,
    version BIGINT NOT NULL DEFAULT 1,

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_api_key_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_api_key_creator FOREIGN KEY (created_by) REFERENCES users(_id),
    CONSTRAINT uq_api_key_hash UNIQUE (key_hash),
    CONSTRAINT chk_api_key_name CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_api_key_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: Hỗ trợ API Gateway tra cứu Key cực nhanh khi xác thực request
-- Query: SELECT tenant_id, scopes, allowed_ips FROM api_keys WHERE key_hash = ? AND (expires_at IS NULL OR expires_at > NOW());
CREATE INDEX idx_api_key_lookup
ON api_keys (key_hash)
WHERE expires_at IS NULL OR expires_at > NOW();

-- Index hỗ trợ Tenant quản lý danh sách Key của mình trong trang cấu hình
CREATE INDEX idx_api_key_tenant_list
ON api_keys (tenant_id, created_at DESC);

-- Index GIN hỗ trợ tìm kiếm các Key có quyền (scope) cụ thể
CREATE INDEX idx_api_key_scopes
ON api_keys USING GIN (scopes);


CREATE TABLE service_accounts (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    member_id UUID NOT NULL,

    -- II. THÔNG TIN XÁC THỰC
    name TEXT NOT NULL,
    description TEXT,
    client_id VARCHAR(64) NOT NULL,
    client_secret_hash TEXT NOT NULL,

    -- III. TRẠNG THÁI & AUDIT
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT uq_service_account_client_id UNIQUE (client_id),
    CONSTRAINT fk_service_account_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_service_account_member FOREIGN KEY (member_id) REFERENCES tenant_members(_id),
    CONSTRAINT chk_service_account_name CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_service_account_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ xác thực cực nhanh khi Bot gọi API
-- Query: SELECT * FROM service_accounts WHERE client_id = ? AND is_active = TRUE;
CREATE INDEX idx_service_account_auth
ON service_accounts (client_id)
WHERE is_active = TRUE;

-- Index hỗ trợ quản trị viên liệt kê các tài khoản máy theo Tenant
CREATE INDEX idx_service_account_tenant_list
ON service_accounts (tenant_id, created_at DESC);


CREATE TABLE user_devices (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    user_id UUID NOT NULL,

    -- II. THÔNG TIN THIẾT BỊ (DEVICE INFO)
    device_fingerprint VARCHAR(255) NOT NULL,
    name TEXT,
    user_agent_parsed JSONB NOT NULL DEFAULT '{}',

    -- III. TRẠNG THÁI BẢO MẬT (SECURITY STATUS)
    trust_status VARCHAR(20) NOT NULL DEFAULT 'UNTRUSTED',
    last_ip INET,

    -- IV. TRUY VẾT THỜI GIAN (AUDIT)
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT uq_device_fingerprint UNIQUE (device_fingerprint),
    CONSTRAINT chk_device_trust_status CHECK (trust_status IN ('UNTRUSTED', 'TRUSTED', 'BLOCKED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ xác thực nhanh thiết bị khi người dùng đăng nhập
-- Truy vấn: SELECT trust_status FROM user_devices WHERE user_id = ? AND device_fingerprint = ?;
CREATE INDEX idx_user_device_lookup
ON user_devices (user_id, device_fingerprint);

-- Index hỗ trợ người dùng quản lý danh sách thiết bị của mình (Để thu hồi/Logout)
CREATE INDEX idx_user_devices_list
ON user_devices (user_id, last_active_at DESC);

-- Index hỗ trợ Admin hệ thống tìm kiếm các thiết bị đang bị chặn (BLOCKED)
CREATE INDEX idx_blocked_devices
ON user_devices (trust_status)
WHERE trust_status = 'BLOCKED';


CREATE TABLE tenant_app_routes (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    app_code VARCHAR(50) NOT NULL,

    -- II. CẤU HÌNH ĐỊNH TUYẾN
    domain VARCHAR(255) NOT NULL,
    path_prefix VARCHAR(100) NOT NULL DEFAULT '/',

    -- III. THÔNG TIN PHỤ TRỢ
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_custom_domain BOOLEAN NOT NULL DEFAULT FALSE,
    ssl_status VARCHAR(20) NOT NULL DEFAULT 'NONE',

    -- IV. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_routes_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_domain_path UNIQUE (domain, path_prefix), -- Đảm bảo cặp Domain+Path là duy nhất toàn sàn [4, 10]
    CONSTRAINT chk_route_domain_fmt CHECK (domain ~ '^[a-z0-9.-]+$'),
    CONSTRAINT chk_route_path_fmt CHECK (path_prefix ~ '^/[a-z0-9-/]*$'),
    CONSTRAINT chk_ssl_status CHECK (ssl_status IN ('NONE', 'PENDING', 'ACTIVE', 'FAILED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index "Thần thánh" cho Router (Covering Index)
-- Giúp API Gateway tìm nhanh tenant_id và app_code từ domain + path
-- Query: SELECT tenant_id, app_code FROM tenant_app_routes WHERE domain = ? AND path_prefix = ?;
CREATE UNIQUE INDEX idx_routes_fast_lookup
ON tenant_app_routes (domain, path_prefix)
INCLUDE (tenant_id, app_code, is_custom_domain);

-- Index hỗ trợ quản lý danh sách Route của một Tenant
CREATE INDEX idx_routes_tenant_list
ON tenant_app_routes (tenant_id, created_at DESC);


CREATE TABLE tenant_rate_limits (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID,
    package_id UUID,

    -- II. CẤU HÌNH GIỚI HẠN
    api_group VARCHAR(50) NOT NULL,
    limit_count INT NOT NULL,
    window_seconds INT NOT NULL DEFAULT 60,

    -- III. TRẠNG THÁI & TRUY VẾT
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_rate_limit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    -- Lưu ý: Cần bảng packages tồn tại trước
    -- CONSTRAINT fk_rate_limit_package FOREIGN KEY (package_id) REFERENCES packages(_id),

    -- Đảm bảo mỗi cặp Tenant + Nhóm API chỉ có 1 cấu hình giới hạn duy nhất
    CONSTRAINT uq_tenant_api_group UNIQUE (tenant_id, api_group),

    CONSTRAINT chk_limit_count CHECK (limit_count > 0),
    CONSTRAINT chk_window_seconds CHECK (window_seconds > 0),
    CONSTRAINT chk_api_group_name CHECK (LENGTH(api_group) > 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ API Gateway tra cứu cấu hình giới hạn cực nhanh
-- Query: SELECT limit_count, window_seconds FROM tenant_rate_limits WHERE tenant_id = ? AND api_group = ? AND is_active = TRUE;
CREATE INDEX idx_rate_limit_lookup
ON tenant_rate_limits (tenant_id, api_group)
WHERE is_active = TRUE;

-- Index hỗ trợ quản trị viên hệ thống lọc cấu hình theo gói cước
CREATE INDEX idx_rate_limit_package
ON tenant_rate_limits (package_id)
WHERE package_id IS NOT NULL;


CREATE TABLE webhooks (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. CẤU HÌNH KỸ THUẬT
    target_url TEXT NOT NULL,
    secret_key TEXT NOT NULL,
    subscribed_events TEXT[] NOT NULL,

    -- III. TRẠNG THÁI VẬN HÀNH
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    failure_count INT NOT NULL DEFAULT 0,

    -- IV. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_webhook_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_webhook_url_fmt CHECK (target_url ~* '^https?://'),
    CONSTRAINT chk_webhook_fail_count CHECK (failure_count >= 0),
    CONSTRAINT chk_webhook_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ Event Worker tìm nhanh các webhook đang đăng ký một sự kiện cụ thể
-- Query: SELECT target_url, secret_key FROM webhooks WHERE is_active = TRUE AND 'user.created' = ANY(subscribed_events);
CREATE INDEX idx_webhooks_active_events
ON webhooks USING GIN (subscribed_events)
WHERE is_active = TRUE;

-- Index hỗ trợ Tenant quản lý danh sách Webhook của mình
CREATE INDEX idx_webhooks_tenant_list
ON webhooks (tenant_id, created_at DESC);


CREATE TABLE saas_products (
    -- I. Định danh (Identity)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ phía Application

    -- II. Thông tin nghiệp vụ (Business Data)
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    product_type VARCHAR(20) NOT NULL DEFAULT 'APP',
    description TEXT,

    -- III. Tài chính (Strict Money Rules)
    base_price NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- IV. Trạng thái & Dữ liệu động
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NOT NULL DEFAULT '{}',

    -- V. Audit & Versioning (Standard Mixins)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- VI. Các ràng buộc (Constraints)
    CONSTRAINT uq_saas_products_code UNIQUE (code),
    CONSTRAINT chk_saas_products_code_fmt CHECK (code ~ '^[a-z0-9-]+$'),
    CONSTRAINT chk_saas_products_type CHECK (product_type IN ('APP', 'DOMAIN', 'SSL', 'SERVICE')),
    CONSTRAINT chk_saas_products_price CHECK (base_price >= 0),
    CONSTRAINT chk_saas_products_currency_len CHECK (LENGTH(currency) = 3),
    CONSTRAINT chk_saas_products_name_len CHECK (LENGTH(name) > 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh theo mã sản phẩm (thường dùng cho Routing/Checkout)
CREATE UNIQUE INDEX idx_saas_products_code
ON saas_products (code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ lọc danh sách sản phẩm đang kinh doanh theo loại
CREATE INDEX idx_saas_products_active_type
ON saas_products (product_type, is_active)
WHERE deleted_at IS NULL;

-- Index GIN để hỗ trợ truy vấn sâu vào các thuộc tính động trong metadata
CREATE INDEX idx_saas_products_metadata
ON saas_products USING GIN (metadata);

-- Comment mô tả bảng hỗ trợ tài liệu hóa (Documentation)
COMMENT ON TABLE saas_products IS 'Lưu trữ danh mục các dòng sản phẩm thương mại của nền tảng SaaS';



CREATE TABLE applications (
    -- I. Định danh & Mã kỹ thuật
    _id UUID PRIMARY KEY, -- UUID v7 nên được sinh từ tầng Application
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- II. Trạng thái vận hành
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- III. Nhóm Audit & Versioning (Tiêu chuẩn hệ thống)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. Các ràng buộc dữ liệu
    CONSTRAINT uq_applications_code UNIQUE (code),
    CONSTRAINT chk_app_code_format CHECK (code ~ '^[A-Z0-9_]+$'),
    CONSTRAINT chk_app_name_not_empty CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_app_version_valid CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh theo mã ứng dụng (thường dùng khi Routing hoặc Check quyền)
CREATE UNIQUE INDEX idx_applications_code
ON applications (code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ liệt kê các ứng dụng đang hoạt động
CREATE INDEX idx_applications_active
ON applications (is_active)
WHERE deleted_at IS NULL;

-- Comment mô tả bảng (tùy chọn để hỗ trợ Documentation)
COMMENT ON TABLE applications IS 'Lưu trữ danh mục các ứng dụng kỹ thuật trong hệ thống SaaS';
COMMENT ON COLUMN applications._id IS 'Định danh UUID v7 giúp sắp xếp theo thời gian và tối ưu sharding';


CREATE TABLE app_capabilities (
    -- I. Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application
    app_code VARCHAR(50) NOT NULL,

    -- II. Thông tin nghiệp vụ
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL,
    default_value JSONB NOT NULL,
    description TEXT,

    -- III. Trạng thái & Vận hành
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- IV. Audit & Versioning (Standard Mixins)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- V. Các ràng buộc dữ liệu
    CONSTRAINT fk_cap_app FOREIGN KEY (app_code) REFERENCES applications(code),
    CONSTRAINT uq_app_cap_code UNIQUE (app_code, code), -- Một App không được trùng mã khả năng
    CONSTRAINT chk_cap_code_fmt CHECK (code ~ '^[a-z0-9_]+$'),
    CONSTRAINT chk_cap_type CHECK (type IN ('BOOLEAN', 'NUMBER')),
    CONSTRAINT chk_cap_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm tất cả khả năng của một ứng dụng
CREATE INDEX idx_app_capabilities_app ON app_capabilities (app_code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ tra cứu nhanh khi cấu hình gói cước
CREATE UNIQUE INDEX idx_app_capabilities_lookup ON app_capabilities (app_code, code)
WHERE deleted_at IS NULL;

-- Index cho phép lọc theo loại (Feature vs Limit)
CREATE INDEX idx_app_capabilities_type ON app_capabilities (type)
WHERE is_active = TRUE AND deleted_at IS NULL;


CREATE TABLE service_packages (
    -- I. Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application
    saas_product_id UUID NOT NULL,

    -- II. Thông tin thương mại
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- III. Tài chính (Sử dụng NUMERIC theo chuẩn nguồn [4])
    price_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- IV. Cấu hình quyền hạn (Sử dụng JSONB theo chuẩn nguồn [2])
    entitlements_config JSONB NOT NULL DEFAULT '{}',

    -- V. Trạng thái vận hành
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_public BOOLEAN NOT NULL DEFAULT TRUE,

    -- VI. Audit & Versioning
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- VII. Ràng buộc (Constraints)
    CONSTRAINT fk_package_product FOREIGN KEY (saas_product_id) REFERENCES products(_id),
    CONSTRAINT uq_package_code UNIQUE (code),
    CONSTRAINT chk_package_code_format CHECK (code ~ '^[a-z0-9-]+$'),
    CONSTRAINT chk_package_price CHECK (price_amount >= 0),
    CONSTRAINT chk_package_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm tất cả các gói thuộc một dòng sản phẩm (VD: Lấy các gói của 'HRM Suite')
CREATE INDEX idx_packages_product ON service_packages (saas_product_id)
WHERE deleted_at IS NULL;

-- Index hỗ trợ tra cứu nhanh gói cước qua mã (Dùng khi checkout/mua hàng)
CREATE UNIQUE INDEX idx_packages_code_lookup ON service_packages (code)
WHERE deleted_at IS NULL;

-- Index GIN hỗ trợ tìm kiếm bên trong JSONB (VD: Tìm tất cả gói có chứa App 'CRM') [18, 19]
CREATE INDEX idx_packages_entitlements ON service_packages USING GIN (entitlements_config);

-- Index hỗ trợ lọc các gói đang hoạt động và công khai cho trang chủ/giá cả
CREATE INDEX idx_packages_active_public ON service_packages (status, is_public)
WHERE status = 'ACTIVE' AND is_public = TRUE AND deleted_at IS NULL;



CREATE TABLE tenant_subscriptions (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- UUID v7 sinh từ Application
    tenant_id UUID NOT NULL,
    package_id UUID NOT NULL,

    -- Tài chính (Snapshot)
    price_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- Quyền hạn & Cache (Snapshot & Computed)
    granted_entitlements JSONB NOT NULL DEFAULT '{}',
    -- Tự động trích xuất mã các App từ JSONB để index
    granted_app_codes TEXT[] GENERATED ALWAYS AS (
        ARRAY(SELECT jsonb_object_keys(granted_entitlements))
    ) STORED,

    -- Thời gian & Trạng thái
    start_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Ràng buộc (Constraints)
    CONSTRAINT fk_subs_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_subs_package FOREIGN KEY (package_id) REFERENCES service_packages(_id),
    CONSTRAINT chk_subs_price CHECK (price_amount >= 0),
    CONSTRAINT chk_subs_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'CANCELLED', 'PAST_DUE')),
    CONSTRAINT chk_subs_dates CHECK (end_at IS NULL OR end_at > start_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index kiểm tra quyền truy cập App (Sử dụng GIN Index cho mảng cache)
-- Giúp query: WHERE 'HRM_APP' = ANY(granted_app_codes) chạy cực nhanh [11]
CREATE INDEX idx_subs_granted_apps
ON tenant_subscriptions USING GIN (granted_app_codes);

-- Index tra cứu các thuê bao đang hoạt động của 1 Tenant
CREATE INDEX idx_subs_tenant_active
ON tenant_subscriptions (tenant_id)
WHERE status = 'ACTIVE' AND deleted_at IS NULL;

-- Index hỗ trợ Worker tính tiền Metering hoặc quét thuê bao hết hạn
CREATE INDEX idx_subs_expiry_scan
ON tenant_subscriptions (status, end_at)
WHERE end_at IS NOT NULL;


CREATE TABLE subscription_orders (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- UUID v7 sinh từ Application
    tenant_id UUID NOT NULL,
    created_by UUID,
    
    -- II. THÔNG TIN NGHIỆP VỤ
    order_number VARCHAR(50) NOT NULL,
    po_number	VARCHAR(50),
    type VARCHAR(20) NOT NULL DEFAULT 'NEW',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    
    -- III. TÀI CHÍNH (Sử dụng NUMERIC để đảm bảo độ chính xác)
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',
    subtotal_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    credit_applied	NUMERIC(19,4)	NOT NULL DEFAULT 0,	-- Số tiền trừ từ ví tín dụng (tenant_wallets).
    total_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    
    -- IV. SNAPSHOT DỮ LIỆU (JSONB thay thế bảng con)
    -- Cấu trúc: [{ "product_id": "...", "name": "Gói Pro", "price": 100, "qty": 1 }]
    items_snapshot JSONB NOT NULL DEFAULT '[]', 
    
    -- Cấu trúc: { "tax_id": "010...", "company_name": "ABC Corp", "address": "..." }
    billing_info JSONB NOT NULL DEFAULT '{}',
    
    -- V. THANH TOÁN
    payment_method VARCHAR(30),
    payment_ref_id VARCHAR(100),
    
    -- VI. AUDIT & VERSIONING
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- RÀNG BUỘC TOÀN VẸN
    CONSTRAINT fk_order_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_order_user FOREIGN KEY (created_by) REFERENCES users(_id),
    
    CONSTRAINT uq_order_number UNIQUE (order_number),
    
    CONSTRAINT chk_order_amounts CHECK (total_amount >= 0 AND subtotal_amount >= 0 AND credit_applied >= 0),
    CONSTRAINT chk_order_currency CHECK (LENGTH(currency_code) = 3),
    CONSTRAINT chk_order_status CHECK (status IN ('DRAFT', 'PENDING', 'PAID', 'CANCELLED', 'FAILED', 'REFUNDED')),
    CONSTRAINT chk_order_type CHECK (type IN ('NEW', 'RENEWAL', 'UPGRADE', 'DOWNGRADE', 'ADD_ON'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index 1: Hỗ trợ Tenant xem lịch sử đơn hàng (Sắp xếp mới nhất lên đầu)
CREATE INDEX idx_orders_tenant_history 
ON subscription_orders (tenant_id, created_at DESC) 
WHERE deleted_at IS NULL;

-- Index 2: Hỗ trợ Worker quét các đơn hàng treo (PENDING) quá lâu để hủy
CREATE INDEX idx_orders_pending_process 
ON subscription_orders (status, created_at) 
WHERE status = 'PENDING' AND deleted_at IS NULL;

-- Index 3: Tìm kiếm nhanh theo mã đơn hàng nghiệp vụ
CREATE UNIQUE INDEX idx_orders_number_lookup 
ON subscription_orders (order_number);

-- Index 4: GIN Index hỗ trợ tìm kiếm đơn hàng có chứa sản phẩm cụ thể trong JSONB
-- Ví dụ: Tìm các đơn hàng có mua gói "ENTERPRISE_PACK"
CREATE INDEX idx_orders_items_gin 
ON subscription_orders USING GIN (items_snapshot);


CREATE TABLE subscription_invoices (
    -- I. ĐỊNH DANH
    _id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    subscription_id UUID,
    order_id UUID, -- Liên kết tới đơn hàng (Optional)
    
    -- II. THÔNG TIN NGHIỆP VỤ
    invoice_number VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',
    
    -- III. CHI TIẾT TÀI CHÍNH (FINANCIAL BREAKDOWN)
    -- Sử dụng NUMERIC(19,4) để đảm bảo độ chính xác tuyệt đối
    subtotal NUMERIC(19, 4) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    total_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(19, 4) NOT NULL DEFAULT 0,
    
    -- Cột tính toán tự động (Generated Column) để truy vấn nợ nhanh
    amount_due NUMERIC(19, 4) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
    
    -- IV. SNAPSHOT DỮ LIỆU (IMMUTABLE DATA)
    -- Cấu trúc: { "name": "Cty A", "tax_id": "123", "address": "Hanoi" }
    customer_snapshot JSONB NOT NULL DEFAULT '{}', 
    
    -- Cấu trúc: [{ "name": "Gói Pro", "qty": 1, "price": 100, "total": 100 }]
    line_items JSONB NOT NULL DEFAULT '[]',
    
    -- Cấu trúc: [{ "name": "VAT", "rate": 10, "amount": 10 }]
    tax_breakdown JSONB NOT NULL DEFAULT '[]',

    -- V. THỜI GIAN & CHU KỲ (REVENUE RECOGNITION)
    billing_period_start TIMESTAMPTZ NOT NULL,
    billing_period_end TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    
    -- VI. HỆ THỐNG & AUDIT
    metadata JSONB NOT NULL DEFAULT '{}', -- Stripe ID, Note
    price_adjustments JSONB NOT NULL DEFAULT '[]',
    pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- RÀNG BUỘC
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),
    CONSTRAINT fk_inv_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_inv_sub FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),
    CONSTRAINT fk_inv_order FOREIGN KEY (order_id) REFERENCES subscription_orders(_id),
    
    CONSTRAINT chk_inv_status CHECK (status IN ('DRAFT', 'OPEN', 'PAID', 'VOID', 'UNCOLLECTIBLE')),
    CONSTRAINT chk_inv_amounts CHECK (subtotal >= 0 AND total_amount >= 0),
    CONSTRAINT chk_inv_dates CHECK (billing_period_end >= billing_period_start),
    CONSTRAINT chk_inv_currency CHECK (LENGTH(currency_code) = 3)
);

-- CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- 1. Index tìm kiếm hóa đơn của khách hàng (Sắp xếp mới nhất lên đầu)
CREATE INDEX idx_invoices_tenant_history 
ON subscription_invoices (tenant_id, created_at DESC) 
WHERE deleted_at IS NULL;

-- 2. Index hỗ trợ nhắc nợ: Tìm các hóa đơn đang mở và đã quá hạn thanh toán
CREATE INDEX idx_invoices_overdue 
ON subscription_invoices (status, due_date) 
WHERE status = 'OPEN' AND due_date < NOW() AND deleted_at IS NULL;

-- 3. Index hỗ trợ tìm kiếm theo Mã hóa đơn nghiệp vụ
CREATE UNIQUE INDEX idx_invoices_number_lookup 
ON subscription_invoices (invoice_number);

-- 4. Index hỗ trợ tra cứu hóa đơn từ đơn hàng gốc
CREATE INDEX idx_invoices_order_lookup 
ON subscription_invoices (order_id) 
WHERE order_id IS NOT NULL;



CREATE TABLE tenant_usages (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    subscription_id UUID NOT NULL,

    -- Dữ liệu tiêu dùng
    usage_period_start TIMESTAMPTZ NOT NULL,
    usage_period_end TIMESTAMPTZ NOT NULL,
    metrics_data JSONB NOT NULL DEFAULT '{}',

    -- Trạng thái & Audit
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Các ràng buộc
    CONSTRAINT fk_usage_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_usage_subscription FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),
    CONSTRAINT chk_usage_dates CHECK (usage_period_end > usage_period_start),
    CONSTRAINT chk_usage_status CHECK (status IN ('PENDING', 'BILLED', 'VOID'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ Job Billing quét nhanh các bản ghi chưa tính tiền theo kỳ
-- Giúp tăng tốc độ xuất hóa đơn hàng tháng
CREATE INDEX idx_usage_billing_scan
ON tenant_usages (status, usage_period_end)
WHERE status = 'PENDING';

-- Index hỗ trợ Tenant xem lịch sử tiêu dùng theo thời gian
CREATE INDEX idx_usage_tenant_history
ON tenant_usages (tenant_id, usage_period_start DESC);

-- Index GIN để truy vấn sâu vào các chỉ số cụ thể trong JSONB nếu cần
-- Ví dụ: Tìm các tenant có lượng emails_sent vượt ngưỡng
CREATE INDEX idx_usage_metrics_data ON tenant_usages USING GIN (metrics_data);



CREATE TABLE tenant_wallets (
    -- Định danh & Tenancy
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,

    -- Tài chính & Tiền tệ
    balance NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- Trạng thái & Quản trị
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Các ràng buộc dữ liệu (Constraints)
    CONSTRAINT uq_tenant_wallet UNIQUE (tenant_id),
    CONSTRAINT fk_wallet_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT chk_wallet_balance CHECK (balance >= 0),
    CONSTRAINT chk_currency_code_len CHECK (LENGTH(currency_code) = 3),
    CONSTRAINT chk_wallet_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tra cứu ví nhanh theo ID khách hàng (Bắt buộc cho SaaS)
CREATE INDEX idx_wallets_tenant_lookup ON tenant_wallets (tenant_id);

-- Index hỗ trợ bộ phận kế toán lọc các ví có số dư thấp để gửi cảnh báo nạp tiền
CREATE INDEX idx_wallets_low_balance ON tenant_wallets (balance)
WHERE balance < 100000 AND is_frozen = FALSE;

-- Index hỗ trợ kiểm tra các ví bị đóng băng để xử lý nghiệp vụ
CREATE INDEX idx_wallets_frozen_status ON tenant_wallets (is_frozen)
WHERE is_frozen = TRUE;



CREATE TABLE wallet_transactions (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    wallet_id UUID NOT NULL,

    -- Chi tiết giao dịch
    type VARCHAR(30) NOT NULL,
    amount NUMERIC(19, 4) NOT NULL,
    balance_after NUMERIC(19, 4) NOT NULL,

    -- Tham chiếu & Mô tả
    reference_id UUID,
    description TEXT,

    -- Thời gian
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Các ràng buộc dữ liệu (Constraints)
    CONSTRAINT fk_tx_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_tx_wallet FOREIGN KEY (wallet_id) REFERENCES tenant_wallets(_id),
    CONSTRAINT chk_tx_type CHECK (type IN ('DEPOSIT', 'USAGE_DEDUCT', 'REFUND', 'BONUS')),
    CONSTRAINT chk_tx_amount_not_zero CHECK (amount <> 0),
    CONSTRAINT chk_tx_balance_after CHECK (balance_after >= 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: Tra cứu lịch sử biến động của 1 ví theo thời gian giảm dần
-- Phục vụ tính năng "Sao kê tài khoản" cho khách hàng
CREATE INDEX idx_wallet_history
ON wallet_transactions (wallet_id, created_at DESC);

-- Index hỗ trợ bộ phận kế toán đối soát theo loại giao dịch (VD: Tìm tất cả REFUND)
CREATE INDEX idx_wallet_tx_type
ON wallet_transactions (tenant_id, type)
WHERE type IN ('REFUND', 'BONUS');

-- Index hỗ trợ tra cứu nhanh từ hóa đơn/đơn hàng sang giao dịch ví
CREATE INDEX idx_wallet_tx_reference
ON wallet_transactions (reference_id)
WHERE reference_id IS NOT NULL;



CREATE TABLE license_allocations (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    subscription_id UUID NOT NULL,

    -- Thông tin hạn ngạch
    license_type VARCHAR(30) NOT NULL DEFAULT 'BILLABLE',
    purchased_quantity INTEGER NOT NULL DEFAULT 0,
    assigned_quantity INTEGER NOT NULL DEFAULT 0,

    -- Trạng thái & Thời gian
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ,

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ràng buộc toàn vẹn (Constraints)
    CONSTRAINT fk_license_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_license_subscription FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),
    CONSTRAINT chk_license_limit CHECK (assigned_quantity <= purchased_quantity),
    CONSTRAINT chk_license_positive CHECK (purchased_quantity >= 0 AND assigned_quantity >= 0),
    CONSTRAINT chk_license_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'SUSPENDED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ kiểm tra hạn ngạch cực nhanh khi Admin mời thêm người dùng mới
-- Giúp query: WHERE tenant_id = ? AND license_type = 'BILLABLE' AND status = 'ACTIVE'
CREATE INDEX idx_license_check_limit
ON license_allocations (tenant_id, license_type, status)
WHERE status = 'ACTIVE';

-- Index hỗ trợ hệ thống Billing quét các giấy phép sắp hết hạn để gửi thông báo
CREATE INDEX idx_license_expiry_scan
ON license_allocations (expires_at, status)
WHERE expires_at IS NOT NULL;

-- Index hỗ trợ truy vấn lịch sử giấy phép của một Tenant cụ thể
CREATE INDEX idx_license_tenant_history
ON license_allocations (tenant_id, created_at DESC);



CREATE TABLE price_adjustments (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application [2]
    tenant_id UUID NOT NULL,
    subscription_id UUID NOT NULL,
    invoice_id UUID,

    -- Chi tiết tài chính
    type VARCHAR(20) NOT NULL,
    amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- Nghiệp vụ & Giải trình
    reason TEXT NOT NULL,
    source VARCHAR(30) NOT NULL DEFAULT 'MANUAL',

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Các ràng buộc (Constraints) [6, 8]
    CONSTRAINT fk_adj_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_adj_subscription FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),
    CONSTRAINT fk_adj_invoice FOREIGN KEY (invoice_id) REFERENCES subscription_invoices(_id),
    CONSTRAINT chk_adj_type CHECK (type IN ('DISCOUNT', 'SURCHARGE', 'TAX', 'REBATE')),
    CONSTRAINT chk_adj_amount CHECK (amount >= 0),
    CONSTRAINT chk_adj_currency CHECK (LENGTH(currency_code) = 3),
    CONSTRAINT chk_adj_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY) [10]

-- Index hỗ trợ lấy tất cả các khoản điều chỉnh cho một Tenant cụ thể
CREATE INDEX idx_price_adj_tenant ON price_adjustments (tenant_id, created_at DESC);

-- Index hỗ trợ liệt kê các khoản giảm giá/phụ phí của một thuê bao (Subscription)
CREATE INDEX idx_price_adj_subscription ON price_adjustments (subscription_id);

-- Index hỗ trợ đối soát hóa đơn: Tìm các điều chỉnh thuộc về một hóa đơn nhất định
CREATE INDEX idx_price_adj_invoice ON price_adjustments (invoice_id)
WHERE invoice_id IS NOT NULL;



CREATE TABLE tenant_encryption_keys (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ phía Application
    tenant_id UUID NOT NULL,

    -- Dữ liệu khóa nhạy cảm
    encrypted_data_key BYTEA NOT NULL,
    key_version INTEGER NOT NULL DEFAULT 1,
    algorithm VARCHAR(50) NOT NULL DEFAULT 'AES-256-GCM',

    -- Trạng thái & Vòng đời
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    rotation_at TIMESTAMPTZ,

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Các ràng buộc (Constraints)
    CONSTRAINT fk_key_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_key_status CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
    CONSTRAINT chk_key_version CHECK (key_version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy khóa mới nhất (phiên bản cao nhất) của một Tenant nhanh chóng
-- Phục vụ logic: Lấy khóa để giải mã dữ liệu mỗi khi có request
CREATE INDEX idx_tenant_key_active
ON tenant_encryption_keys (tenant_id, key_version DESC)
WHERE status = 'ACTIVE';

-- Index hỗ trợ hệ thống bảo mật quét các khóa sắp đến hạn xoay vòng
CREATE INDEX idx_key_rotation_scan
ON tenant_encryption_keys (rotation_at)
WHERE rotation_at IS NOT NULL AND status = 'ACTIVE';

-- Index phục vụ Audit log: Tìm kiếm lịch sử khóa của Tenant theo thời gian
CREATE INDEX idx_key_audit_history
ON tenant_encryption_keys (tenant_id, created_at DESC);



CREATE TABLE tenant_i18n_overrides (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- UUID v7 sinh từ phía Application
    tenant_id UUID NOT NULL,

    -- Nội dung Đa ngôn ngữ
    locale VARCHAR(10) NOT NULL DEFAULT 'vi-VN',
    translation_key VARCHAR(255) NOT NULL,
    custom_value TEXT NOT NULL,

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID,

    -- Ràng buộc (Constraints)
    CONSTRAINT fk_i18n_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    -- Đảm bảo mỗi key chỉ bị ghi đè 1 lần trên mỗi ngôn ngữ của 1 tenant
    CONSTRAINT uq_tenant_locale_key UNIQUE (tenant_id, locale, translation_key),
    CONSTRAINT chk_i18n_version CHECK (version >= 1),
    CONSTRAINT chk_i18n_key_len CHECK (LENGTH(translation_key) > 0)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy toàn bộ các thuật ngữ ghi đè của một Tenant khi đăng nhập
-- Giúp Backend load nhanh dữ liệu để cache lên Redis/Session [13, 14]
CREATE INDEX idx_i18n_tenant_lookup
ON tenant_i18n_overrides (tenant_id, locale);

-- Index hỗ trợ tra cứu lịch sử thay đổi (nếu cần audit)
CREATE INDEX idx_i18n_created_at
ON tenant_i18n_overrides (created_at DESC);



CREATE TABLE system_jobs (
    -- Định danh & Phân loại
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ phía Application
    tenant_id UUID,
    job_type VARCHAR(50) NOT NULL,

    -- Dữ liệu & Trạng thái
    payload JSONB NOT NULL DEFAULT '{}',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    -- Thời gian (Sử dụng TIMESTAMPTZ theo chuẩn UTC)
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,

    -- Quản lý lỗi & Thử lại
    retry_count INT NOT NULL DEFAULT 0,
    max_retries INT NOT NULL DEFAULT 3,
    last_error TEXT,

    -- Quản trị
    created_by UUID,
    version BIGINT NOT NULL DEFAULT 1,

    -- Các ràng buộc dữ liệu
    CONSTRAINT fk_job_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_job_status CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    CONSTRAINT chk_retry_logic CHECK (retry_count <= max_retries)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (Tối ưu cho Worker)

-- Index quan trọng nhất: Giúp Worker tìm nhanh các job đang chờ để xử lý
-- Sử dụng Partial Index để giữ index nhỏ gọn và nhanh
CREATE INDEX idx_jobs_fetch
ON system_jobs (scheduled_at ASC)
WHERE status = 'PENDING';

-- Index hỗ trợ Tenant theo dõi tiến độ các công việc của họ trên UI
CREATE INDEX idx_jobs_tenant_monitor
ON system_jobs (tenant_id, status, scheduled_at DESC);

-- Index hỗ trợ tìm kiếm các công việc bị lỗi để hệ thống tự động xử lý/báo cáo
CREATE INDEX idx_jobs_failed_analysis
ON system_jobs (job_type)
WHERE status = 'FAILED';



CREATE TABLE feature_flags (
    -- Định danh & Khóa kỹ thuật
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ phía Application
    flag_key VARCHAR(50) NOT NULL,
    description TEXT,

    -- Trạng thái & Quy tắc
    is_global_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    rules JSONB NOT NULL DEFAULT '{}',

    -- Quản trị hệ thống
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ràng buộc dữ liệu
    CONSTRAINT uq_flag_key UNIQUE (flag_key),
    CONSTRAINT chk_flag_key_format CHECK (flag_key ~ '^[A-Z0-9_]+$') -- Chỉ cho phép chữ hoa, số và gạch dưới
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh theo mã tính năng
CREATE INDEX idx_flags_lookup ON feature_flags (flag_key);

-- Index GIN để truy vấn các điều kiện bên trong JSONB rules
-- Ví dụ: Tìm các cờ đang áp dụng cho một tenant_id cụ thể
CREATE INDEX idx_flags_rules_search ON feature_flags USING GIN (rules);

-- Index hỗ trợ lọc các tính năng đang hoạt động (Partial Index)
CREATE INDEX idx_flags_active_global ON feature_flags (flag_key)
WHERE is_global_enabled = TRUE;





CREATE TABLE system_announcements (
    -- Định danh & Phân cấp
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application

    -- Nội dung Đa ngôn ngữ (JSONB giúp schema linh hoạt)
    titles JSONB NOT NULL DEFAULT '{}',
    contents JSONB NOT NULL DEFAULT '{}',
    type VARCHAR(20) NOT NULL DEFAULT 'INFO',

    -- Nhắm mục tiêu (Targeting)
    target_regions TEXT[],
    target_plans TEXT[],

    -- Vận hành & Thời gian
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_local_time BOOLEAN NOT NULL DEFAULT FALSE,
    start_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_at TIMESTAMPTZ,

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ràng buộc dữ liệu (Constraints)
    CONSTRAINT chk_announcement_type CHECK (type IN ('INFO', 'WARNING', 'CRITICAL', 'PROMOTION')),
    CONSTRAINT chk_announcement_dates CHECK (end_at IS NULL OR end_at > start_at),
    CONSTRAINT chk_version_valid CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy các thông báo đang có hiệu lực (Partial Index)
-- Tối ưu cho API Gateway mỗi khi người dùng load trang
CREATE INDEX idx_announcements_active_pull ON system_announcements (start_at DESC)
WHERE is_active = TRUE;

-- Index GIN để tìm kiếm nhanh theo vùng địa lý hoặc gói cước (Multi-targeting)
CREATE INDEX idx_announcements_regions ON system_announcements USING GIN (target_regions);
CREATE INDEX idx_announcements_plans ON system_announcements USING GIN (target_plans);



CREATE TABLE notification_templates (
    -- Định danh & Phân tách
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID,

    -- Định danh nghiệp vụ
    code VARCHAR(100) NOT NULL,
    name TEXT NOT NULL,

    -- Nội dung đa ngôn ngữ & Đa kênh (JSONB)
    subject_templates JSONB NOT NULL DEFAULT '{}',
    body_templates JSONB NOT NULL DEFAULT '{}',
    sms_template TEXT,

    -- Metadata kỹ thuật
    required_variables TEXT[] DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ràng buộc (Constraints)
    CONSTRAINT fk_template_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_template_code_fmt CHECK (code ~ '^[A-Z0-9_]+$'), -- Chỉ chữ hoa, số và gạch dưới
    CONSTRAINT chk_template_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX

-- Index đảm bảo tính duy nhất của mã code trong phạm vi một Tenant hoặc Global
-- Trường hợp mẫu hệ thống (Global)
CREATE UNIQUE INDEX uq_global_template_code
ON notification_templates (code)
WHERE tenant_id IS NULL;

-- Trường hợp mẫu riêng của từng Tenant
CREATE UNIQUE INDEX uq_tenant_template_code
ON notification_templates (tenant_id, code)
WHERE tenant_id IS NOT NULL;

-- Index hỗ trợ lấy danh sách mẫu đang hoạt động của Tenant
CREATE INDEX idx_templates_lookup
ON notification_templates (tenant_id, is_active)
WHERE is_active = TRUE;


CREATE TABLE user_announcement_reads (
    -- Định danh & Phân tách
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    announcement_id UUID NOT NULL,

    -- Thời gian & Trạng thái
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- Ràng buộc toàn vẹn (Constraints)
    CONSTRAINT fk_read_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_read_user FOREIGN KEY (user_id) REFERENCES users(_id) ON DELETE CASCADE,
    CONSTRAINT fk_read_announcement FOREIGN KEY (announcement_id) REFERENCES system_announcements(_id) ON DELETE CASCADE,

    -- [QUAN TRỌNG] Đảm bảo tính duy nhất: 1 User chỉ đọc 1 thông báo 1 lần
    CONSTRAINT uq_user_announcement UNIQUE (user_id, announcement_id),
    CONSTRAINT chk_read_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ lấy danh sách các thông báo mà 1 user ĐÃ ĐỌC
-- Kết hợp với bảng system_announcements để loại trừ (filter out) khi hiển thị
CREATE INDEX idx_user_reads_lookup ON user_announcement_reads (user_id, announcement_id);

-- Index hỗ trợ báo cáo cho Admin: "Có bao nhiêu người đã đọc thông báo X?"
CREATE INDEX idx_announcement_read_stats ON user_announcement_reads (announcement_id);



# 3. MongoDB command
db.createCollection("tenant_app_configs", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["_id", "tenant_id", "app_code", "configs", "version", "created_at", "updated_at"],
         properties: {
            _id: { bsonType: "string", description: "Must be a UUID v7 string" },
            tenant_id: { bsonType: "string", description: "Must be a UUID string of the tenant" },
            app_code: { bsonType: "string", description: "App code identifier (e.g., HRM, CRM)" },
            configs: { bsonType: "object", description: "Flexible configuration object" },
            version: { bsonType: "long", minimum: 1 },
            created_at: { bsonType: "date" },
            updated_at: { bsonType: "date" }
         }
      }
   }
});
Câu lệnh tạo Index (Chỉ mục)
Các chỉ mục này giúp tối ưu hóa việc tra cứu cấu hình cho từng ứng dụng của từng khách hàng và hỗ trợ quá trình đồng bộ dữ liệu (CDC),.
// 1. Index duy nhất: Đảm bảo một Tenant chỉ có một bộ cấu hình cho mỗi App
db.tenant_app_configs.createIndex(
    { "tenant_id": 1, "app_code": 1 },
    { unique: true, name: "idx_tenant_app_unique" }
);

// 2. Index cho Sharding: Tối ưu hóa việc phân tán dữ liệu theo khách hàng
// Thường sử dụng tenant_id làm Shard Key trong kiến trúc SaaS
db.tenant_app_configs.createIndex({ "tenant_id": 1 });

// 3. Index hỗ trợ CDC/Sync: Tìm kiếm các bản ghi mới cập nhật để đẩy sang ClickHouse
db.tenant_app_configs.createIndex({ "updated_at": -1 });

// 4. Index hỗ trợ tìm kiếm sâu trong JSON (GIN Index tương đương trong Mongo)
// Ví dụ: Tìm các tenant đang cấu hình theme_color là 'blue'
db.tenant_app_configs.createIndex({ "configs.theme_color": 1 }, { sparse: true });

