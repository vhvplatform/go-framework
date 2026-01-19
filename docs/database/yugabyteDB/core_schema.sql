SET search_path TO core;

CREATE TABLE IF NOT EXISTS tenants (
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
    CONSTRAINT fk_tenants_parent FOREIGN KEY (parent_tenant_id) REFERENCES core.tenants(_id),
    CONSTRAINT chk_tenants_status CHECK (status IN ('TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED')),
    CONSTRAINT chk_tenants_region CHECK (data_region IN ('ap-southeast-1', 'us-east-1', 'eu-central-1')),
    CONSTRAINT chk_tenants_compliance CHECK (compliance_level IN ('STANDARD', 'GDPR', 'HIPAA', 'PCI-DSS')),
    CONSTRAINT chk_tenants_billing CHECK (billing_type IN ('PREPAID', 'POSTPAID')),
    CONSTRAINT chk_tenants_updated CHECK (updated_at >= created_at),
    CONSTRAINT chk_tenants_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ xác thực và điều hướng (Login/Routing) theo subdomain/slug
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_code_active
ON tenants (code)
WHERE deleted_at IS NULL;


-- Index GIN hỗ trợ tìm kiếm trong Profile (Ví dụ: tìm theo Mã số thuế trong JSON)
CREATE INDEX IF NOT EXISTS idx_tenants_profile_gin
ON tenants USING GIN (profile);

-- Index hỗ trợ báo cáo quản trị hệ thống theo khu vực và gói cước
CREATE INDEX IF NOT EXISTS idx_tenants_infra_stats
ON tenants (data_region, tier, status);
-- Index hỗ trợ truy vấn cấu trúc cây đối tác phân phối (Materialized Path) [12, 13]
CREATE INDEX IF NOT EXISTS idx_tenants_path ON tenants (path ASC) WHERE deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS applications (
    -- I. Định danh & Mã kỹ thuật
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
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
    CONSTRAINT chk_app_version_valid CHECK (version >= 1),
    CONSTRAINT chk_app_updated CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh theo mã ứng dụng (dùng khi Routing hoặc Check quyền)
-- Sử dụng Partial Index để chỉ quét các ứng dụng chưa bị xóa mềm
CREATE UNIQUE INDEX IF NOT EXISTS idx_applications_code
ON applications (code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ liệt kê các ứng dụng đang hoạt động để gán vào Gói dịch vụ
CREATE INDEX IF NOT EXISTS idx_applications_active
ON applications (is_active)
WHERE deleted_at IS NULL;

-- Comment mô tả bảng (hỗ trợ tài liệu hóa Documentation tự động)
COMMENT ON TABLE applications IS 'Lưu trữ danh mục các ứng dụng kỹ thuật độc lập trong hệ thống SaaS';




CREATE TABLE IF NOT EXISTS users (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_active
ON users (email)
WHERE deleted_at IS NULL;

-- Index tìm kiếm mờ (Fuzzy Search) bằng search text dạng LIKE
CREATE INDEX IF NOT EXISTS idx_users_full_name_pattern
ON users (full_name text_pattern_ops);

CREATE INDEX IF NOT EXISTS idx_users_email_pattern
ON users (email text_pattern_ops);

-- Index hỗ trợ quản trị viên lọc user theo trạng thái và thời gian tạo [18]
CREATE INDEX IF NOT EXISTS idx_users_status_created
ON users (status, created_at DESC);



CREATE TABLE IF NOT EXISTS tenant_members (
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
CREATE INDEX IF NOT EXISTS idx_mem_tenant ON tenant_members (tenant_id) WHERE deleted_at IS NULL;

-- GIN Index để tìm kiếm trong custom_data (Ví dụ: tìm theo mã nhân viên lưu trong JSON)
CREATE INDEX IF NOT EXISTS idx_mem_custom_data ON tenant_members USING GIN (custom_data);


CREATE TABLE IF NOT EXISTS departments (
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
CREATE INDEX IF NOT EXISTS idx_dept_path ON departments (tenant_id, path text_pattern_ops) WHERE deleted_at IS NULL;

-- Index hỗ trợ tìm kiếm phòng ban theo Tenant (SaaS isolation) [6], [13]
CREATE INDEX IF NOT EXISTS idx_dept_tenant ON departments (tenant_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS department_members (
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
CREATE INDEX IF NOT EXISTS idx_dept_mem_lookup
ON department_members (tenant_id, department_id);

-- Index hỗ trợ tìm tất cả các phòng ban mà một nhân viên đang tham gia
CREATE INDEX IF NOT EXISTS idx_dept_mem_member
ON department_members (tenant_id, member_id);

-- Index lọc nhanh những nhân sự thuộc phòng ban chính (dùng cho báo cáo nhân sự)
CREATE INDEX IF NOT EXISTS idx_dept_mem_primary
ON department_members (tenant_id, is_primary)
WHERE is_primary = TRUE;


CREATE TABLE IF NOT EXISTS user_groups (
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
CREATE INDEX IF NOT EXISTS idx_groups_tenant ON user_groups (tenant_id);

-- Index hỗ trợ truy vấn cấu trúc cây (Hierarchy) bằng Materialized Path [9]
-- Sử dụng text_pattern_ops để tối ưu cho toán tử LIKE 'path/%'
CREATE INDEX IF NOT EXISTS idx_groups_path ON user_groups (tenant_id, path text_pattern_ops);

-- Index hỗ trợ tìm kiếm nhanh theo loại nhóm
CREATE INDEX IF NOT EXISTS idx_groups_type ON user_groups (tenant_id, type);


CREATE TABLE IF NOT EXISTS group_members (
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
CREATE INDEX IF NOT EXISTS idx_gm_lookup_group
ON group_members (tenant_id, group_id);

-- Index hỗ trợ tìm tất cả các nhóm mà một nhân sự đang tham gia (Access Pattern: User Profile)
CREATE INDEX IF NOT EXISTS idx_gm_lookup_member
ON group_members (tenant_id, member_id);


CREATE TABLE IF NOT EXISTS location_types (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_loctype_tenant_code
ON location_types (tenant_id, code)
WHERE tenant_id IS NOT NULL;

-- B. Đảm bảo tính duy nhất của Code cho hệ thống (System Types)
CREATE UNIQUE INDEX IF NOT EXISTS idx_loctype_system_code
ON location_types (code)
WHERE tenant_id IS NULL;

-- C. Index hỗ trợ load danh sách loại địa điểm cho Tenant
-- (Bao gồm cả loại của Tenant đó VÀ loại của Hệ thống)
CREATE INDEX IF NOT EXISTS idx_loctype_lookup
ON location_types (tenant_id, is_active)
WHERE is_active = TRUE;

-- D. Index GIN để tìm kiếm/validate trong cấu hình trường động
CREATE INDEX IF NOT EXISTS idx_loctype_extra_fields
ON location_types USING GIN (extra_fields);

CREATE TABLE IF NOT EXISTS locations (
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
CREATE INDEX IF NOT EXISTS idx_locations_tenant
ON locations (tenant_id, status)
WHERE deleted_at IS NULL;

-- Index "Thần thánh" cho cây phân cấp (Materialized Path)
-- Giúp query: Lấy tất cả phòng ban con của Chi nhánh A (WHERE path LIKE '/A/%')
CREATE INDEX IF NOT EXISTS idx_locations_path
ON locations (tenant_id, path text_pattern_ops)
WHERE deleted_at IS NULL;

-- Index GIN hỗ trợ tìm kiếm sâu trong dữ liệu động (Metadata)
-- VD: Tìm tất cả kho hàng có diện tích > 500m2 (lưu trong metadata)
CREATE INDEX IF NOT EXISTS idx_locations_metadata
ON locations USING GIN (metadata);

-- Index hỗ trợ tìm kiếm trụ sở chính
CREATE INDEX IF NOT EXISTS idx_locations_hq
ON locations (tenant_id)
WHERE is_headquarter = TRUE AND deleted_at IS NULL;



CREATE TABLE IF NOT EXISTS user_linked_identities (
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
CREATE INDEX IF NOT EXISTS idx_identity_lookup
ON user_linked_identities (provider, provider_id);

-- Index hỗ trợ trang quản lý tài khoản: Hiển thị các phương thức đã liên kết của 1 user
CREATE INDEX IF NOT EXISTS idx_identity_user_id
ON user_linked_identities (user_id);


CREATE TABLE IF NOT EXISTS user_sessions (
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
CREATE INDEX IF NOT EXISTS idx_sessions_user_active
ON user_sessions (user_id)
WHERE is_revoked = FALSE;

-- Index hỗ trợ quét các phiên đã hết hạn để dọn dẹp (Cleanup Job)
CREATE INDEX IF NOT EXISTS idx_sessions_expiry
ON user_sessions (expires_at)
WHERE is_revoked = FALSE;

-- Index hỗ trợ kiểm tra nhanh token trong cùng một family khi thực hiện rotation [6]
CREATE INDEX IF NOT EXISTS idx_sessions_family
ON user_sessions (family_id);


CREATE TABLE IF NOT EXISTS user_mfa_methods (
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
CREATE INDEX IF NOT EXISTS idx_user_mfa_lookup
ON user_mfa_methods (user_id);

-- Index một phần (Partial Index) để xác định nhanh phương thức mặc định của người dùng
CREATE INDEX IF NOT EXISTS idx_user_mfa_default
ON user_mfa_methods (user_id)
WHERE is_default = TRUE;

CREATE TABLE IF NOT EXISTS user_webauthn_credentials (
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
CREATE INDEX IF NOT EXISTS idx_webauthn_user_lookup
ON user_webauthn_credentials (user_id);

-- Index hỗ trợ việc xác thực dựa trên Credential ID trả về từ trình duyệt
CREATE INDEX IF NOT EXISTS idx_webauthn_credential_lookup
ON user_webauthn_credentials (credential_id);


CREATE TABLE IF NOT EXISTS user_backup_codes (
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
CREATE INDEX IF NOT EXISTS idx_backup_user_lookup
ON user_backup_codes (user_id);

-- Partial Index: Chỉ index các mã chưa sử dụng để tăng tốc độ xác thực khi login
-- Giảm dung lượng index và tăng hiệu năng do không chứa các mã đã dùng
CREATE INDEX IF NOT EXISTS idx_backup_unused_codes
ON user_backup_codes (user_id)
WHERE is_used = FALSE;


CREATE TABLE IF NOT EXISTS tenant_sso_configs (
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
CREATE INDEX IF NOT EXISTS idx_sso_enforced ON tenant_sso_configs (is_enforced) WHERE is_enforced = TRUE;

-- Index hỗ trợ tìm kiếm cấu hình theo loại nhà cung cấp
CREATE INDEX IF NOT EXISTS idx_sso_provider ON tenant_sso_configs (provider_type);



CREATE TABLE IF NOT EXISTS auth_verification_codes (
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
CREATE INDEX IF NOT EXISTS idx_auth_codes_lookup
ON auth_verification_codes (tenant_id, identifier, type, expires_at DESC);

-- Index hỗ trợ dọn dẹp các mã đã hết hạn (Cleanup Job)
-- Sử dụng Partial Index để chỉ tập trung vào các bản ghi đã quá hạn
CREATE INDEX IF NOT EXISTS idx_auth_codes_cleanup
ON auth_verification_codes (expires_at);


CREATE TABLE IF NOT EXISTS personal_access_tokens (
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
CREATE INDEX IF NOT EXISTS idx_pat_auth_lookup
ON personal_access_tokens (token_hash)
WHERE is_active = TRUE;

-- Index hỗ trợ trang quản lý: Hiển thị danh sách token của một người dùng trong một Tenant
CREATE INDEX IF NOT EXISTS idx_pat_user_list
ON personal_access_tokens (tenant_id, user_id);

-- Index hỗ trợ các tác vụ dọn dẹp (Cleanup) token đã hết hạn
CREATE INDEX IF NOT EXISTS idx_pat_expiry
ON personal_access_tokens (expires_at)
WHERE expires_at IS NOT NULL;


CREATE TABLE IF NOT EXISTS roles (
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
CREATE INDEX IF NOT EXISTS idx_roles_tenant_lookup
ON roles (tenant_id);

-- Index GIN hỗ trợ tìm kiếm các vai trò có chứa một mã quyền cụ thể
-- Query: SELECT * FROM roles WHERE 'user:view' = ANY(permission_codes);
CREATE INDEX IF NOT EXISTS idx_roles_permissions
ON roles USING GIN (permission_codes);



CREATE TABLE IF NOT EXISTS permissions (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_permissions_code_lookup
ON permissions (code);

-- Index hỗ trợ lọc danh sách quyền theo từng ứng dụng
CREATE INDEX IF NOT EXISTS idx_permissions_app_filter
ON permissions (app_code);

-- Index "thần thánh" hỗ trợ truy vấn cấu trúc cây (Materialized Path)
-- Giúp query: WHERE path LIKE '/HRM/%' đạt hiệu năng O(log N)
CREATE INDEX IF NOT EXISTS idx_permissions_path_tree
ON permissions (path text_pattern_ops);

-- Comment để hỗ trợ Documentation
COMMENT ON TABLE permissions IS 'Danh mục quyền hạn hệ thống hỗ trợ phân cấp nhiều tầng';



CREATE TABLE IF NOT EXISTS user_roles (
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
CREATE INDEX IF NOT EXISTS idx_ur_member_lookup
ON user_roles (member_id, tenant_id);

-- Index hỗ trợ tìm kiếm: "Ai là Manager của Department X?"
CREATE INDEX IF NOT EXISTS idx_ur_scope_search
ON user_roles USING GIN (scope_values)
WHERE scope_type = 'DEPARTMENT';


CREATE TABLE IF NOT EXISTS relationship_tuples (
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
CREATE INDEX IF NOT EXISTS idx_tuples_reverse_lookup
ON relationship_tuples (tenant_id, subject_id, relation, namespace);

-- Index hỗ trợ kiểm tra quyền theo loại tài nguyên (Namespace)
CREATE INDEX IF NOT EXISTS idx_tuples_namespace_lookup
ON relationship_tuples (tenant_id, namespace, relation);


CREATE TABLE IF NOT EXISTS access_control_lists (
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
CREATE INDEX IF NOT EXISTS idx_acl_lookup
ON access_control_lists (tenant_id, resource_id, subject_id);

-- Index hỗ trợ việc lấy danh sách tất cả các tài nguyên mà một Member/Group có quyền truy cập
CREATE INDEX IF NOT EXISTS idx_acl_subject_search
ON access_control_lists (tenant_id, subject_id, subject_type);

CREATE TABLE IF NOT EXISTS tenant_domains (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_domain_lookup
ON tenant_domains (domain)
WHERE verification_status = 'VERIFIED';

-- Index hỗ trợ việc quản lý danh sách domain của một Tenant cụ thể
CREATE INDEX IF NOT EXISTS idx_tenant_domain_list
ON tenant_domains (tenant_id);


CREATE TABLE IF NOT EXISTS tenant_invitations (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_invitation_token_lookup
ON tenant_invitations (token)
WHERE status = 'PENDING';

-- Index hỗ trợ Admin quản lý danh sách lời mời của một Tenant (Theo dõi tiến độ Onboarding)
CREATE INDEX IF NOT EXISTS idx_invitation_tenant_list
ON tenant_invitations (tenant_id, created_at DESC);

-- Index hỗ trợ Job dọn dẹp hoặc tự động cập nhật trạng thái hết hạn
-- For Yugabyte: avoid volatile functions (NOW()) in partial index predicates.
-- Index for cleanup jobs: index by status and expires_at so queries can filter expires_at against current time at runtime.
CREATE INDEX IF NOT EXISTS idx_invitation_expiry_cleanup
ON tenant_invitations (status, expires_at)
WHERE status = 'PENDING';


CREATE TABLE IF NOT EXISTS access_reviews (
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
CREATE INDEX IF NOT EXISTS idx_access_reviews_tenant_lookup
ON access_reviews (tenant_id, created_at DESC);

-- Index hỗ trợ hệ thống quản trị theo dõi các đợt rà soát sắp đến hạn
-- Giúp chạy các Background Jobs gửi thông báo nhắc nhở (Reminder)
CREATE INDEX IF NOT EXISTS idx_access_reviews_deadline
ON access_reviews (status, deadline)
WHERE status IN ('PENDING', 'IN_PROGRESS');


CREATE TABLE IF NOT EXISTS access_review_items (
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
CREATE INDEX IF NOT EXISTS idx_review_items_reviewer_task
ON access_review_items (reviewer_id, review_id)
WHERE decision = 'PENDING';

-- Index hỗ trợ báo cáo tiến độ: "Có bao nhiêu mục đã hoàn thành trong đợt rà soát X?"
CREATE INDEX IF NOT EXISTS idx_review_items_status
ON access_review_items (review_id, decision);

-- Index hỗ trợ lịch sử nhân viên: "Nhân viên A đã từng bị thu hồi những quyền gì trong quá khứ?"
CREATE INDEX IF NOT EXISTS idx_review_items_target_history
ON access_review_items (target_member_id)
WHERE decision = 'REVOKE';


CREATE TABLE IF NOT EXISTS scim_directories (
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
CREATE INDEX IF NOT EXISTS idx_scim_auth_lookup
ON scim_directories (scim_token_hash)
WHERE is_active = TRUE;

-- Index hỗ trợ trang quản trị: Hiển thị danh sách kết nối thư mục của một Tenant
CREATE INDEX IF NOT EXISTS idx_scim_tenant_list
ON scim_directories (tenant_id);


CREATE TABLE IF NOT EXISTS scim_mappings (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_scim_external_sync
ON scim_mappings (directory_id, external_id, internal_entity_type);

-- Index hỗ trợ tìm ngược từ hệ thống nội bộ để gửi update sang IdP (Deprovisioning)
-- Query: SELECT external_id FROM scim_mappings WHERE internal_entity_id = ?;
CREATE INDEX IF NOT EXISTS idx_scim_internal_lookup
ON scim_mappings (internal_entity_id);


CREATE TABLE IF NOT EXISTS tenant_security_policies (
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
CREATE INDEX IF NOT EXISTS idx_security_policies_updated ON tenant_security_policies (updated_at DESC);


CREATE TABLE IF NOT EXISTS legal_documents (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_active_version
ON legal_documents (type)
WHERE is_active = TRUE;

-- Index hỗ trợ tra cứu lịch sử thay đổi của một loại văn bản theo thời gian
CREATE INDEX IF NOT EXISTS idx_legal_history_lookup
ON legal_documents (type, published_at DESC);


CREATE TABLE IF NOT EXISTS user_consents (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_consent_lookup
ON user_consents (user_id, document_id);

-- Index hỗ trợ báo cáo tuân thủ và truy vết pháp lý (Audit Trail)
-- Query: SELECT * FROM user_consents WHERE agreed_at BETWEEN ? AND ?;
CREATE INDEX IF NOT EXISTS idx_consent_audit_history
ON user_consents (agreed_at DESC);


CREATE TABLE IF NOT EXISTS user_delegations (
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
-- Avoid NOW() in predicate. Include expires_at in index columns and keep predicate on immutable column is_active.
CREATE INDEX IF NOT EXISTS idx_delegation_lookup_delegatee
ON user_delegations (tenant_id, delegatee_id, expires_at)
WHERE is_active = TRUE;

-- Index hỗ trợ người ủy quyền kiểm tra xem mình đã cấp quyền cho những ai
CREATE INDEX IF NOT EXISTS idx_delegation_lookup_delegator
ON user_delegations (tenant_id, delegator_id);


CREATE TABLE IF NOT EXISTS api_keys (
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
-- Avoid NOW() in predicate. Create index covering key_hash and expires_at. Queries should still filter by expires_at at runtime.
CREATE INDEX IF NOT EXISTS idx_api_key_lookup
ON api_keys (key_hash, expires_at);

-- Index hỗ trợ Tenant quản lý danh sách Key của mình trong trang cấu hình
CREATE INDEX IF NOT EXISTS idx_api_key_tenant_list
ON api_keys (tenant_id, created_at DESC);



CREATE TABLE IF NOT EXISTS service_accounts (
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
CREATE INDEX IF NOT EXISTS idx_service_account_auth
ON service_accounts (client_id)
WHERE is_active = TRUE;

-- Index hỗ trợ quản trị viên liệt kê các tài khoản máy theo Tenant
CREATE INDEX IF NOT EXISTS idx_service_account_tenant_list
ON service_accounts (tenant_id, created_at DESC);


CREATE TABLE IF NOT EXISTS user_devices (
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
CREATE INDEX IF NOT EXISTS idx_user_device_lookup
ON user_devices (user_id, device_fingerprint);

-- Index hỗ trợ người dùng quản lý danh sách thiết bị của mình (Để thu hồi/Logout)
CREATE INDEX IF NOT EXISTS idx_user_devices_list
ON user_devices (user_id, last_active_at DESC);

-- Index hỗ trợ Admin hệ thống tìm kiếm các thiết bị đang bị chặn (BLOCKED)
CREATE INDEX IF NOT EXISTS idx_blocked_devices
ON user_devices (trust_status)
WHERE trust_status = 'BLOCKED';


CREATE TABLE IF NOT EXISTS tenant_app_routes (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_routes_fast_lookup
ON tenant_app_routes (domain, path_prefix)
INCLUDE (tenant_id, app_code, is_custom_domain);

-- Index hỗ trợ quản lý danh sách Route của một Tenant
CREATE INDEX IF NOT EXISTS idx_routes_tenant_list
ON tenant_app_routes (tenant_id, created_at DESC);


CREATE TABLE IF NOT EXISTS tenant_rate_limits (
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
CREATE INDEX IF NOT EXISTS idx_rate_limit_lookup
ON tenant_rate_limits (tenant_id, api_group)
WHERE is_active = TRUE;

-- Index hỗ trợ quản trị viên hệ thống lọc cấu hình theo gói cước
CREATE INDEX IF NOT EXISTS idx_rate_limit_package
ON tenant_rate_limits (package_id)
WHERE package_id IS NOT NULL;


CREATE TABLE IF NOT EXISTS webhooks (
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
CREATE INDEX IF NOT EXISTS idx_webhooks_active_events
ON webhooks USING GIN (subscribed_events)
WHERE is_active = TRUE;

-- Index hỗ trợ Tenant quản lý danh sách Webhook của mình
CREATE INDEX IF NOT EXISTS idx_webhooks_tenant_list
ON webhooks (tenant_id, created_at DESC);

CREATE TABLE IF NOT EXISTS saas_product_types (
    -- I. ĐỊNH DANH & MÃ KỸ THUẬT
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,

    -- II. TRẠNG THÁI VẬN HÀNH
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- III. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- IV. CÁC RÀNG BUỘC
    CONSTRAINT uq_product_type_code UNIQUE (code),
    CONSTRAINT chk_product_type_code_fmt CHECK (code ~ '^[A-Z0-9_]+$'),
    CONSTRAINT chk_product_type_name_len CHECK (LENGTH(name) > 0),
    CONSTRAINT chk_product_type_updated CHECK (updated_at >= created_at),
    CONSTRAINT chk_product_type_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm nhanh theo mã loại sản phẩm (Dùng khi validate dữ liệu)
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_types_code_lookup
ON saas_product_types (code)
WHERE is_active = TRUE;

-- Index hỗ trợ hiển thị danh sách các loại sản phẩm đang hoạt động trên Admin UI
CREATE INDEX IF NOT EXISTS idx_product_types_active
ON saas_product_types (is_active, created_at DESC);

-- COMMENT để hỗ trợ tài liệu hóa
COMMENT ON TABLE saas_product_types IS 'Bảng danh mục định nghĩa các loại sản phẩm thương mại của hệ thống SaaS';




CREATE TABLE IF NOT EXISTS saas_products (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_saas_products_code
ON saas_products (code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ lọc danh sách sản phẩm đang kinh doanh theo loại
CREATE INDEX IF NOT EXISTS idx_saas_products_active_type
ON saas_products (product_type, is_active)
WHERE deleted_at IS NULL;

-- Index GIN để hỗ trợ truy vấn sâu vào các thuộc tính động trong metadata
CREATE INDEX IF NOT EXISTS idx_saas_products_metadata
ON saas_products USING GIN (metadata);

-- Comment mô tả bảng hỗ trợ tài liệu hóa (Documentation)
COMMENT ON TABLE saas_products IS 'Lưu trữ danh mục các dòng sản phẩm thương mại của nền tảng SaaS';



CREATE TABLE IF NOT EXISTS applications (
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_applications_code
ON applications (code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ liệt kê các ứng dụng đang hoạt động
CREATE INDEX IF NOT EXISTS idx_applications_active
ON applications (is_active)
WHERE deleted_at IS NULL;

-- Comment mô tả bảng (tùy chọn để hỗ trợ Documentation)
COMMENT ON TABLE applications IS 'Lưu trữ danh mục các ứng dụng kỹ thuật trong hệ thống SaaS';
COMMENT ON COLUMN applications._id IS 'Định danh UUID v7 giúp sắp xếp theo thời gian và tối ưu sharding';


CREATE TABLE IF NOT EXISTS app_capabilities (
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
CREATE INDEX IF NOT EXISTS idx_app_capabilities_app ON app_capabilities (app_code)
WHERE deleted_at IS NULL;

-- Index hỗ trợ tra cứu nhanh khi cấu hình gói cước
CREATE UNIQUE INDEX IF NOT EXISTS idx_app_capabilities_lookup ON app_capabilities (app_code, code)
WHERE deleted_at IS NULL;

-- Index cho phép lọc theo loại (Feature vs Limit)
CREATE INDEX IF NOT EXISTS idx_app_capabilities_type ON app_capabilities (type)
WHERE is_active = TRUE AND deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS service_packages (
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
    CONSTRAINT fk_package_product FOREIGN KEY (saas_product_id) REFERENCES saas_products(_id),
    CONSTRAINT uq_package_code UNIQUE (code),
    CONSTRAINT chk_package_code_format CHECK (code ~ '^[a-z0-9-]+$'),
    CONSTRAINT chk_package_price CHECK (price_amount >= 0),
    CONSTRAINT chk_package_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ tìm kiếm tất cả các gói thuộc một dòng sản phẩm (VD: Lấy các gói của 'HRM Suite')
CREATE INDEX IF NOT EXISTS idx_packages_product ON service_packages (saas_product_id)
WHERE deleted_at IS NULL;

-- Index hỗ trợ tra cứu nhanh gói cước qua mã (Dùng khi checkout/mua hàng)
CREATE UNIQUE INDEX IF NOT EXISTS idx_packages_code_lookup ON service_packages (code)
WHERE deleted_at IS NULL;

-- Index GIN hỗ trợ tìm kiếm bên trong JSONB (VD: Tìm tất cả gói có chứa App 'CRM') [18, 19]
CREATE INDEX IF NOT EXISTS idx_packages_entitlements ON service_packages USING GIN (entitlements_config);

-- Index hỗ trợ lọc các gói đang hoạt động và công khai cho trang chủ/giá cả
CREATE INDEX IF NOT EXISTS idx_packages_active_public ON service_packages (status, is_public)
WHERE status = 'ACTIVE' AND is_public = TRUE AND deleted_at IS NULL;



CREATE TABLE IF NOT EXISTS tenant_subscriptions (
    -- Định danh & Liên kết
    _id UUID PRIMARY KEY, -- UUID v7 sinh từ Application
    tenant_id UUID NOT NULL,
    package_id UUID NOT NULL,

    -- Tài chính (Snapshot)
    price_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- Quyền hạn & Cache (Snapshot & Computed)
    granted_entitlements JSONB NOT NULL DEFAULT '{}',

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

-- Index tra cứu các thuê bao đang hoạt động của 1 Tenant
CREATE INDEX IF NOT EXISTS idx_subs_tenant_active
ON tenant_subscriptions (tenant_id)
WHERE status = 'ACTIVE' AND deleted_at IS NULL;

-- Index hỗ trợ Worker tính tiền Metering hoặc quét thuê bao hết hạn
CREATE INDEX IF NOT EXISTS idx_subs_expiry_scan
ON tenant_subscriptions (status, end_at)
WHERE end_at IS NOT NULL;


CREATE TABLE IF NOT EXISTS subscription_orders (
    -- Định danh & Tenancy
    _id UUID PRIMARY KEY, -- UUID v7 sinh từ ứng dụng
    tenant_id UUID NOT NULL,
    package_id UUID NOT NULL,

    -- Thông tin đơn hàng
    order_number VARCHAR(50) NOT NULL,
    total_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(30),

    -- Dữ liệu Snapshot (Quan trọng để bảo toàn giá/quyền lợi khi mua)
    package_snapshot JSONB NOT NULL DEFAULT '{}',

    -- Quản trị & Audit
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Các ràng buộc toàn vẹn
    CONSTRAINT fk_order_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_order_package FOREIGN KEY (package_id) REFERENCES service_packages(_id),
    CONSTRAINT uq_order_number UNIQUE (order_number),
    CONSTRAINT chk_order_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_order_currency CHECK (LENGTH(currency_code) = 3),
    CONSTRAINT chk_order_status CHECK (status IN ('PENDING', 'PAID', 'CANCELLED', 'FAILED'))
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ Tenant xem lịch sử đơn hàng (Sắp xếp mới nhất lên đầu)
CREATE INDEX IF NOT EXISTS idx_orders_tenant_lookup
ON subscription_orders (tenant_id, created_at DESC)
WHERE deleted_at IS NULL;

-- Index hỗ trợ Admin/Worker quét các đơn hàng chưa thanh toán
CREATE INDEX IF NOT EXISTS idx_orders_pending_status
ON subscription_orders (status, created_at)
WHERE status = 'PENDING' AND deleted_at IS NULL;

-- Index tìm kiếm nhanh theo mã đơn hàng nghiệp vụ
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_number_search
ON subscription_orders (order_number)
WHERE deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS subscription_invoices (
    -- I. ĐỊNH DANH & LIÊN KẾT (IDENTITY & LINKING)
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    partner_id UUID, -- Dùng cho mô hình phân phối đa tầng
    subscription_id UUID NOT NULL,
    invoice_number VARCHAR(50) NOT NULL,

    -- II. TÀI CHÍNH (STRICT FINANCIAL RULES)
    amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    -- III. CHU KỲ & HẠN THANH TOÁN
    billing_period_start TIMESTAMPTZ NOT NULL,
    billing_period_end TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,

    -- IV. DỮ LIỆU SNAPSHOT & MỞ RỘNG
    price_adjustments JSONB NOT NULL DEFAULT '[]',
    metadata JSONB NOT NULL DEFAULT '{}',

    -- V. QUẢN TRỊ & AUDIT
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id),
    CONSTRAINT fk_invoice_partner FOREIGN KEY (partner_id) REFERENCES tenants(_id),
    CONSTRAINT fk_invoice_subscription FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),
    CONSTRAINT chk_invoice_status CHECK (status IN ('DRAFT', 'OPEN', 'PAID', 'VOID', 'UNCOLLECTIBLE')),
    CONSTRAINT chk_billing_dates CHECK (billing_period_end > billing_period_start),
    CONSTRAINT chk_invoice_currency CHECK (LENGTH(currency_code) = 3),
    CONSTRAINT chk_invoice_version CHECK (version >= 1),
    CONSTRAINT chk_invoice_updated CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index hỗ trợ Tenant/Partner tra cứu lịch sử hóa đơn cực nhanh (SaaS Isolation)
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_lookup
ON subscription_invoices (tenant_id, created_at DESC)
WHERE deleted_at IS NULL;

-- Index hỗ trợ đối soát công nợ cho Đối tác phân phối (Distribution Partner)
CREATE INDEX IF NOT EXISTS idx_invoices_partner_debt
ON subscription_invoices (partner_id, status)
WHERE partner_id IS NOT NULL AND status != 'PAID';

-- Index hỗ trợ nhắc nợ tự động: Tìm các hóa đơn 'OPEN' đã quá hạn thanh toán
CREATE INDEX IF NOT EXISTS idx_invoices_overdue_tracker
ON subscription_invoices (status, due_date)
WHERE status = 'OPEN' AND deleted_at IS NULL;

-- Index tìm kiếm nhanh theo mã hóa đơn (Search UI)
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoices_number_search
ON subscription_invoices (invoice_number)
WHERE deleted_at IS NULL;



CREATE TABLE IF NOT EXISTS tenant_usages (
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
CREATE INDEX IF NOT EXISTS idx_usage_billing_scan
ON tenant_usages (status, usage_period_end)
WHERE status = 'PENDING';

-- Index hỗ trợ Tenant xem lịch sử tiêu dùng theo thời gian
CREATE INDEX IF NOT EXISTS idx_usage_tenant_history
ON tenant_usages (tenant_id, usage_period_start DESC);



CREATE TABLE IF NOT EXISTS tenant_wallets (
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
CREATE INDEX IF NOT EXISTS idx_wallets_tenant_lookup ON tenant_wallets (tenant_id);

-- Index hỗ trợ bộ phận kế toán lọc các ví có số dư thấp để gửi cảnh báo nạp tiền
CREATE INDEX IF NOT EXISTS idx_wallets_low_balance ON tenant_wallets (balance)
WHERE balance < 100000 AND is_frozen = FALSE;

-- Index hỗ trợ kiểm tra các ví bị đóng băng để xử lý nghiệp vụ
CREATE INDEX IF NOT EXISTS idx_wallets_frozen_status ON tenant_wallets (is_frozen)
WHERE is_frozen = TRUE;



CREATE TABLE IF NOT EXISTS wallet_transactions (
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
CREATE INDEX IF NOT EXISTS idx_wallet_history
ON wallet_transactions (wallet_id, created_at DESC);

-- Index hỗ trợ bộ phận kế toán đối soát theo loại giao dịch (VD: Tìm tất cả REFUND)
CREATE INDEX IF NOT EXISTS idx_wallet_tx_type
ON wallet_transactions (tenant_id, type)
WHERE type IN ('REFUND', 'BONUS');

-- Index hỗ trợ tra cứu nhanh từ hóa đơn/đơn hàng sang giao dịch ví
CREATE INDEX IF NOT EXISTS idx_wallet_tx_reference
ON wallet_transactions (reference_id)
WHERE reference_id IS NOT NULL;



CREATE TABLE IF NOT EXISTS license_allocations (
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
CREATE INDEX IF NOT EXISTS idx_license_check_limit
ON license_allocations (tenant_id, license_type, status)
WHERE status = 'ACTIVE';

-- Index hỗ trợ hệ thống Billing quét các giấy phép sắp hết hạn để gửi thông báo
CREATE INDEX IF NOT EXISTS idx_license_expiry_scan
ON license_allocations (expires_at, status)
WHERE expires_at IS NOT NULL;

-- Index hỗ trợ truy vấn lịch sử giấy phép của một Tenant cụ thể
CREATE INDEX IF NOT EXISTS idx_license_tenant_history
ON license_allocations (tenant_id, created_at DESC);



CREATE TABLE IF NOT EXISTS price_adjustments (
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
CREATE INDEX IF NOT EXISTS idx_price_adj_tenant ON price_adjustments (tenant_id, created_at DESC);

-- Index hỗ trợ liệt kê các khoản giảm giá/phụ phí của một thuê bao (Subscription)
CREATE INDEX IF NOT EXISTS idx_price_adj_subscription ON price_adjustments (subscription_id);

-- Index hỗ trợ đối soát hóa đơn: Tìm các điều chỉnh thuộc về một hóa đơn nhất định
CREATE INDEX IF NOT EXISTS idx_price_adj_invoice ON price_adjustments (invoice_id)
WHERE invoice_id IS NOT NULL;



CREATE TABLE IF NOT EXISTS tenant_encryption_keys (
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
CREATE INDEX IF NOT EXISTS idx_tenant_key_active
ON tenant_encryption_keys (tenant_id, key_version DESC)
WHERE status = 'ACTIVE';

-- Index hỗ trợ hệ thống bảo mật quét các khóa sắp đến hạn xoay vòng
CREATE INDEX IF NOT EXISTS idx_key_rotation_scan
ON tenant_encryption_keys (rotation_at)
WHERE rotation_at IS NOT NULL AND status = 'ACTIVE';

-- Index phục vụ Audit log: Tìm kiếm lịch sử khóa của Tenant theo thời gian
CREATE INDEX IF NOT EXISTS idx_key_audit_history
ON tenant_encryption_keys (tenant_id, created_at DESC);



CREATE TABLE IF NOT EXISTS tenant_i18n_overrides (
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
CREATE INDEX IF NOT EXISTS idx_i18n_tenant_lookup
ON tenant_i18n_overrides (tenant_id, locale);

-- Index hỗ trợ tra cứu lịch sử thay đổi (nếu cần audit)
CREATE INDEX IF NOT EXISTS idx_i18n_created_at
ON tenant_i18n_overrides (created_at DESC);



CREATE TABLE IF NOT EXISTS system_jobs (
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
CREATE INDEX IF NOT EXISTS idx_jobs_fetch
ON system_jobs (scheduled_at ASC)
WHERE status = 'PENDING';

-- Index hỗ trợ Tenant theo dõi tiến độ các công việc của họ trên UI
CREATE INDEX IF NOT EXISTS idx_jobs_tenant_monitor
ON system_jobs (tenant_id, status, scheduled_at DESC);

-- Index hỗ trợ tìm kiếm các công việc bị lỗi để hệ thống tự động xử lý/báo cáo
CREATE INDEX IF NOT EXISTS idx_jobs_failed_analysis
ON system_jobs (job_type)
WHERE status = 'FAILED';



CREATE TABLE IF NOT EXISTS feature_flags (
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
CREATE INDEX IF NOT EXISTS idx_flags_lookup ON feature_flags (flag_key);

-- Index hỗ trợ lọc các tính năng đang hoạt động (Partial Index)
CREATE INDEX IF NOT EXISTS idx_flags_active_global ON feature_flags (flag_key)
WHERE is_global_enabled = TRUE;





CREATE TABLE IF NOT EXISTS system_announcements (
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
CREATE INDEX IF NOT EXISTS idx_announcements_active_pull ON system_announcements (start_at DESC)
WHERE is_active = TRUE;






CREATE TABLE IF NOT EXISTS notification_templates (
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
CREATE UNIQUE INDEX IF NOT EXISTS uq_global_template_code
ON notification_templates (code)
WHERE tenant_id IS NULL;

-- Trường hợp mẫu riêng của từng Tenant
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_template_code
ON notification_templates (tenant_id, code)
WHERE tenant_id IS NOT NULL;

-- Index hỗ trợ lấy danh sách mẫu đang hoạt động của Tenant
CREATE INDEX IF NOT EXISTS idx_templates_lookup
ON notification_templates (tenant_id, is_active)
WHERE is_active = TRUE;


CREATE TABLE IF NOT EXISTS user_announcement_reads (
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
CREATE INDEX IF NOT EXISTS idx_user_reads_lookup ON user_announcement_reads (user_id, announcement_id);

-- Index hỗ trợ báo cáo cho Admin: "Có bao nhiêu người đã đọc thông báo X?"
CREATE INDEX IF NOT EXISTS idx_announcement_read_stats ON user_announcement_reads (announcement_id);


CREATE TABLE IF NOT EXISTS article_types (
    _id UUID PRIMARY KEY,
    app_code VARCHAR(50) NOT NULL REFERENCES applications(code),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    icon_url TEXT,

    -- Định nghĩa cấu trúc dữ liệu bổ sung (nếu cần)
    config_schema JSONB NOT NULL DEFAULT '{}',

    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_article_type_code UNIQUE (app_code, code)
);

-- Index hỗ trợ load danh sách loại bài viết cho 1 App
CREATE INDEX IF NOT EXISTS idx_article_types_app ON article_types (app_code, is_active);



CREATE TABLE IF NOT EXISTS tags (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,

    -- II. NỘI DUNG TAG
    name TEXT NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,

    -- III. TRÌNH BÀY & MỞ RỘNG
    color VARCHAR(7), -- Mã màu Hex (VD: #FF0000)
    metadata JSONB NOT NULL DEFAULT '{}',

    -- IV. THỐNG KÊ (Denormalized)
    usage_count BIGINT NOT NULL DEFAULT 0,

    -- V. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- VI. RÀNG BUỘC TOÀN VẸN
    CONSTRAINT fk_tags_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,

    -- Một Tenant không được có 2 tag trùng slug
    CONSTRAINT uq_tags_slug UNIQUE (tenant_id, slug),

    -- Kiểm tra định dạng Slug (chỉ chữ thường, số, gạch ngang)
    CONSTRAINT chk_tags_slug_fmt CHECK (slug ~ '^[a-z0-9-]+$'),

    -- Kiểm tra định dạng màu Hex
    CONSTRAINT chk_tags_color_fmt CHECK (color IS NULL OR color ~ '^#[A-Fa-f0-9]{6}$'),

    CONSTRAINT chk_tags_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- A. Index quan trọng nhất: Tìm Tag theo Slug để render trang danh sách bài viết theo Tag
-- Query: SELECT * FROM tags WHERE tenant_id = ? AND slug = ?;
-- (Đã được cover bởi Unique Constraint uq_tags_slug, nhưng YB tối ưu cái này rất tốt)

-- B. Index hỗ trợ tìm kiếm/Autocomplete tên Tag trong trang Admin
-- Sử dụng trgm (trigram) index nếu cần tìm kiếm mờ (fuzzy search) hoặc BTree cho prefix search
CREATE INDEX IF NOT EXISTS idx_tags_name_search
ON tags (tenant_id, name)
WHERE name IS NOT NULL;

-- C. Index hỗ trợ sắp xếp Tag phổ biến (Most used tags)
CREATE INDEX IF NOT EXISTS idx_tags_popular
ON tags (tenant_id, usage_count DESC);


CREATE TABLE IF NOT EXISTS routing_slugs (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,

    -- II. THÔNG TIN ĐỊNH TUYẾN (ROUTING INFO)
    slug VARCHAR(255) NOT NULL,
    entity_type VARCHAR(50) NOT NULL, -- VD: 'PRODUCT', 'ARTICLE'
    entity_id UUID NOT NULL,          -- ID của Product hoặc Article

    -- III. TRẠNG THÁI & ĐIỀU HƯỚNG
    is_canonical BOOLEAN NOT NULL DEFAULT TRUE,
    redirect_to VARCHAR(255), -- Slug đích nếu đây là Alias (301 Redirect)

    -- IV. SNAPSHOT & METADATA (Tối ưu hiệu năng đọc)
    -- Ví dụ: { "title": "Áo thun nam", "thumbnail": "url...", "seo_title": "..." }
    items_snapshot JSONB NOT NULL DEFAULT '{}',

    -- V. AUDIT
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- VI. CÁC RÀNG BUỘC (CONSTRAINTS)

    -- Ràng buộc khóa ngoại: Xóa Tenant là xóa hết slug
    CONSTRAINT fk_routing_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,

    -- Ràng buộc duy nhất: Trong 1 Tenant, Slug không được trùng lặp
    CONSTRAINT uq_tenant_slug UNIQUE (tenant_id, slug),

    -- Kiểm tra định dạng Slug (URL Friendly)
    CONSTRAINT chk_routing_slug_fmt CHECK (slug ~ '^[a-z0-9-]+$'),

    -- Kiểm tra logic redirect
    CONSTRAINT chk_routing_redirect CHECK (
        (is_canonical = TRUE AND redirect_to IS NULL) OR
        (is_canonical = FALSE AND redirect_to IS NOT NULL)
    )
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: "Resolve Slug"
-- Giúp tìm ra Entity từ URL: "tenant A + slug /ao-thun -> Là Product ID nào?"
-- (Lưu ý: Constraint UNIQUE ở trên đã tự tạo index, nhưng nếu cần Covering Index để lấy luôn entity_id thì tạo thêm)
-- YugabyteDB tự động dùng index của Constraint UNIQUE cho query này.

-- Index hỗ trợ tìm kiếm ngược (Reverse Lookup)
-- Mục đích: Khi đổi tên bài viết, cần tìm tất cả slug cũ của bài viết đó để cập nhật redirect.
-- Query: SELECT * FROM routing_slugs WHERE tenant_id = ? AND entity_type = ? AND entity_id = ?;
CREATE INDEX IF NOT EXISTS idx_routing_reverse_lookup
ON routing_slugs (tenant_id, entity_type, entity_id);




CREATE TABLE IF NOT EXISTS reserved_slugs (
    -- I. Định danh (Identity)
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application Layer để tối ưu Sharding [1]

    -- II. Thông tin Từ khóa (Slug Info)
    slug VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'SYSTEM',
    match_type VARCHAR(20) NOT NULL DEFAULT 'EXACT',

    -- III. Ngữ cảnh & Snapshot (Context)
    -- items_snapshot: Lưu trữ metadata linh hoạt.
    -- Ví dụ: { "affected_routes": ["/api/v1", "/static"], "reserved_by": "System Admin", "ticket_id": "OPS-123" }
    items_snapshot JSONB NOT NULL DEFAULT '{}',

    reason TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- IV. Audit & Versioning
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. Ràng buộc dữ liệu (Constraints)

    -- Từ khóa cấm phải là duy nhất
    CONSTRAINT uq_reserved_slug UNIQUE (slug),

    -- Chỉ cho phép ký tự URL friendly (chữ thường, số, gạch ngang) [2]
    CONSTRAINT chk_reserved_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),

    -- Kiểm tra giá trị hợp lệ cho phân loại
    CONSTRAINT chk_reserved_type CHECK (type IN ('SYSTEM', 'BUSINESS', 'OFFENSIVE', 'FUTURE')),

    -- Kiểm tra cách thức so khớp
    CONSTRAINT chk_match_type CHECK (match_type IN ('EXACT', 'PREFIX', 'REGEX')),

    -- Kiểm tra logic thời gian
    CONSTRAINT chk_reserved_dates CHECK (updated_at >= created_at),

    -- Kiểm tra phiên bản
    CONSTRAINT chk_reserved_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: Tra cứu nhanh xem một từ khóa có bị cấm không
-- Sử dụng Hash Index nếu chỉ check EXACT match, hoặc B-Tree (mặc định) để hỗ trợ LIKE/Range
CREATE UNIQUE INDEX IF NOT EXISTS idx_reserved_slug_lookup
ON reserved_slugs (slug)
WHERE is_active = TRUE;

-- Index hỗ trợ tìm kiếm các từ khóa cấm theo loại (VD: Lấy danh sách từ cấm Offensive để filter chat)
CREATE INDEX IF NOT EXISTS idx_reserved_type
ON reserved_slugs (type)
WHERE is_active = TRUE;



CREATE TABLE IF NOT EXISTS storage_files (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    parent_id UUID,
    -- Phân loại: File hay Folder?
    is_folder BOOLEAN NOT NULL DEFAULT FALSE,

    -- II. THÔNG TIN FILE & ĐỊNH VỊ
    original_name TEXT NOT NULL,
    storage_path TEXT NOT NULL, -- S3 Key
    public_url TEXT, -- CDN URL đầy đủ cho việc hiển thị nhanh

    category VARCHAR(20) NOT NULL DEFAULT 'MEDIA',
    mime_type VARCHAR(100) NOT NULL,
    extension VARCHAR(20),
    file_size BIGINT NOT NULL DEFAULT 0,

    -- III. DỮ LIỆU MỞ RỘNG & NỘI DUNG
    -- Lưu cấu trúc bên trong của file nén hoặc preview data
    items_snapshot JSONB NOT NULL DEFAULT '[]',

    -- Lưu dimensions, duration, exif, ai_tags, variants
    metadata JSONB NOT NULL DEFAULT '{}',

    -- IV. STORAGE & VẬN HÀNH
    storage_provider VARCHAR(20) NOT NULL DEFAULT 'S3',
    visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    status VARCHAR(20) NOT NULL DEFAULT 'PROCESSING',

    -- V. AUDIT & VERSIONING
    uploaded_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- RÀNG BUỘC TOÀN VẸN
CONSTRAINT fk_storage_parent FOREIGN KEY (parent_id) REFERENCES storage_files(_id) ON DELETE CASCADE,
    CONSTRAINT fk_storage_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT uq_storage_path UNIQUE (tenant_id, storage_path),
    CONSTRAINT chk_file_path CHECK (
        (is_folder = TRUE AND storage_path IS NULL) OR
        (is_folder = FALSE AND storage_path IS NOT NULL)
    ),

    CONSTRAINT chk_storage_cat CHECK (category IN ('MEDIA', 'DOCUMENT', 'ARCHIVE', 'EXPORT', 'SYSTEM')),
    CONSTRAINT chk_storage_status CHECK (status IN ('UPLOADING', 'PROCESSING', 'READY', 'FAILED')),
    CONSTRAINT chk_storage_provider CHECK (storage_provider IN ('S3', 'R2', 'MINIO', 'CLOUDFLARE')),
    CONSTRAINT chk_storage_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- A. Index cốt lõi: Browsing thư viện file theo thư mục
-- Sắp xếp file mới nhất lên đầu trong một thư mục cụ thể của Tenant
CREATE INDEX IF NOT EXISTS idx_storage_browse_folder
ON storage_files (tenant_id, parent_id, created_at DESC)
WHERE deleted_at IS NULL;

-- C. Index lọc theo loại file và category (VD: Lấy tất cả ảnh trong phần Media)
CREATE INDEX IF NOT EXISTS idx_storage_category_mime
ON storage_files (tenant_id, category, mime_type)
WHERE deleted_at IS NULL;

-- D. Index dọn dẹp rác (Garbage Collection)
CREATE INDEX IF NOT EXISTS idx_storage_cleanup
ON storage_files (deleted_at)
WHERE deleted_at IS NOT NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'storage_files'
    ) THEN
        EXECUTE 'DROP TRIGGER IF EXISTS storage_files_set_updated_at ON public.storage_files';
        EXECUTE 'CREATE TRIGGER storage_files_set_updated_at BEFORE INSERT OR UPDATE ON public.storage_files FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at()';
    END IF;
END
$$;



CREATE TABLE IF NOT EXISTS digital_asset_types (
    -- I. ĐỊNH DANH
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application

    -- II. THÔNG TIN LOẠI TÀI SẢN
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,

    -- III. CẤU HÌNH KỸ THUẬT & LOGIC
    -- Định nghĩa cấu trúc dữ liệu bắt buộc cho tài sản thuộc loại này
    attributes_schema JSONB NOT NULL DEFAULT '{}',

    -- Cấu hình nhà cung cấp (VD: Credential của Namecheap/Cloudflare)
    provider_config JSONB NOT NULL DEFAULT '{}',

    -- Tên Job xử lý logic cấp phát (Provisioning)
    provisioning_job VARCHAR(100),

    -- IV. TRẠNG THÁI & LOGIC KINH DOANH
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_renewable BOOLEAN NOT NULL DEFAULT TRUE, -- True: Có hết hạn, False: Vĩnh viễn

    -- V. AUDIT
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- RÀNG BUỘC
    CONSTRAINT uq_asset_type_code UNIQUE (code),
    CONSTRAINT chk_asset_type_code_fmt CHECK (code ~ '^[A-Z0-9_]+$'),
    CONSTRAINT chk_asset_type_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX
-- Index để tra cứu nhanh theo mã (code)
CREATE UNIQUE INDEX IF NOT EXISTS idx_digital_asset_types_code
ON digital_asset_types (code);



CREATE TABLE IF NOT EXISTS tenant_digital_assets (
    -- I. Định danh & Sở hữu
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    order_id UUID,

    -- II. Thông tin Tài sản
    asset_type VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,

    -- III. Cấu hình & Trạng thái
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    asset_metadata JSONB NOT NULL DEFAULT '{}',

    -- IV. Vòng đời & Thời gian
    activated_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. Các Ràng buộc (Constraints)
    CONSTRAINT fk_asset_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_order FOREIGN KEY (order_id) REFERENCES subscription_orders(_id),

    CONSTRAINT fk_asset_type_ref
FOREIGN KEY (asset_type) REFERENCES digital_asset_types(code)
ON UPDATE CASCADE,

    CONSTRAINT chk_asset_status CHECK (status IN ('PENDING', 'PROVISIONING', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'TRANSFERRING')),

    -- Logic thời gian: Ngày hết hạn phải sau ngày kích hoạt (nếu đã kích hoạt)
    CONSTRAINT chk_asset_expiry CHECK (expires_at IS NULL OR activated_at IS NULL OR expires_at > activated_at),

    CONSTRAINT chk_asset_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index 1: Hỗ trợ Tenant xem danh sách tài sản của họ trên Portal
CREATE INDEX IF NOT EXISTS idx_assets_tenant_list
ON tenant_digital_assets (tenant_id, asset_type, created_at DESC);

-- Index 2: Hỗ trợ Job quét các tài sản sắp hết hạn để gửi thông báo hoặc tự động gia hạn
-- Chỉ quét các tài sản đang hoạt động (ACTIVE)
CREATE INDEX IF NOT EXISTS idx_assets_expiry_scan
ON tenant_digital_assets (expires_at)
WHERE status = 'ACTIVE';

-- Index 3: Đảm bảo tính duy nhất của tên miền/tài sản trong hệ thống (tránh 2 người mua cùng 1 domain)
-- Chỉ áp dụng cho các tài sản đang hoạt động hoặc đang xử lý
CREATE UNIQUE INDEX IF NOT EXISTS idx_assets_unique_name
ON tenant_digital_assets (name)
WHERE status IN ('PENDING', 'PROVISIONING', 'ACTIVE', 'TRANSFERRING')
AND asset_type = 'DOMAIN';



CREATE TABLE IF NOT EXISTS tenant_service_deliveries (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID NOT NULL,
    product_id UUID NOT NULL,
    subscription_id UUID,

    -- II. CHI TIẾT SỐ LƯỢNG & GIÁ
    unit_type VARCHAR(20) NOT NULL,
    total_units NUMERIC(15,2) NOT NULL DEFAULT 0,
    delivered_units NUMERIC(15,2) NOT NULL DEFAULT 0,
    unit_price NUMERIC(19,4) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'VND',

    -- III. TRẠNG THÁI & DỮ LIỆU ĐỘNG
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    service_metadata JSONB NOT NULL DEFAULT '{}',

    -- IV. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- V. CÁC RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_service_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_service_product FOREIGN KEY (product_id) REFERENCES saas_products(_id), -- Hoặc service_packages tùy mô hình
    CONSTRAINT fk_service_sub FOREIGN KEY (subscription_id) REFERENCES tenant_subscriptions(_id),

    CONSTRAINT chk_service_status CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_service_units CHECK (total_units > 0 AND delivered_units >= 0),
    CONSTRAINT chk_delivery_logic CHECK (delivered_units <= total_units), -- Không thể giao quá số lượng mua
    CONSTRAINT chk_service_version CHECK (version >= 1),
    CONSTRAINT chk_service_updated CHECK (updated_at >= created_at)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index 1: Giúp bộ phận triển khai (Delivery Team) tìm nhanh các dịch vụ chưa hoàn thành của một khách hàng
-- Query: SELECT * FROM tenant_service_deliveries WHERE tenant_id = ? AND status != 'COMPLETED';
CREATE INDEX IF NOT EXISTS idx_services_pending
ON tenant_service_deliveries (tenant_id, status)
WHERE status != 'COMPLETED';

-- Index 2: Hỗ trợ báo cáo doanh thu theo sản phẩm và thời gian
-- Query: Thống kê doanh thu dịch vụ đào tạo trong tháng này
CREATE INDEX IF NOT EXISTS idx_services_product_revenue
ON tenant_service_deliveries (product_id, created_at DESC);

-- Index 3: Hỗ trợ tra cứu theo gói thuê bao (nếu dịch vụ được bán kèm gói)
CREATE INDEX IF NOT EXISTS idx_services_subscription
ON tenant_service_deliveries (subscription_id)
WHERE subscription_id IS NOT NULL;


CREATE TABLE IF NOT EXISTS oauth_clients (
    -- I. ĐỊNH DANH & TENANCY
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ tầng Application
    tenant_id UUID,

    -- II. THÔNG TIN XÁC THỰC CỐT LÕI
    client_id VARCHAR(64) NOT NULL,
    client_secret_hash TEXT, -- Nullable cho Public Clients (Mobile/SPA)
    client_type VARCHAR(20) NOT NULL DEFAULT 'CONFIDENTIAL',

    -- III. CẤU HÌNH BẢO MẬT & LUỒNG
    grant_types TEXT[] NOT NULL DEFAULT '{"authorization_code", "refresh_token"}',
    redirect_uris TEXT[] NOT NULL DEFAULT '{}',
    allowed_scopes TEXT[] NOT NULL DEFAULT '{}',

    -- Cấu hình Token nâng cao (TTL, Rotation) - Lưu JSONB để linh hoạt
    token_settings JSONB NOT NULL DEFAULT '{
        "access_token_ttl": 3600,
        "refresh_token_ttl": 2592000,
        "rotate_refresh_token": true
    }',

    -- IV. THÔNG TIN HIỂN THỊ (CONSENT SCREEN)
    name TEXT NOT NULL,
    consent_info JSONB NOT NULL DEFAULT '{}', -- Chứa logo_url, privacy_policy_url
    is_trusted BOOLEAN NOT NULL DEFAULT FALSE,

    -- V. TRẠNG THÁI & AUDIT
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,

    -- VI. RÀNG BUỘC
    CONSTRAINT uq_oauth_clients_client_id UNIQUE (client_id),
    CONSTRAINT fk_oauth_clients_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(_id) ON DELETE CASCADE,
    CONSTRAINT chk_client_type CHECK (client_type IN ('CONFIDENTIAL', 'PUBLIC')),
    CONSTRAINT chk_client_status CHECK (status IN ('ACTIVE', 'SUSPENDED')),
    CONSTRAINT chk_client_version CHECK (version >= 1)
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (Tối ưu hóa Lookup cho API Gateway)

-- Index Covering: Giúp API Gateway lấy toàn bộ thông tin cần thiết để validate request
-- mà không cần đọc bảng gốc (Heap fetch). Thêm các cột mới vào INCLUDE.
CREATE UNIQUE INDEX IF NOT EXISTS idx_oauth_clients_lookup
ON oauth_clients (client_id)
INCLUDE (client_secret_hash, client_type, redirect_uris, grant_types, token_settings, status, is_trusted)
WHERE status = 'ACTIVE'; -- Chỉ index các Client đang hoạt động để tối ưu

-- Index hỗ trợ Admin quản lý danh sách App của Tenant
CREATE INDEX IF NOT EXISTS idx_oauth_clients_tenant
ON oauth_clients (tenant_id, created_at DESC);



