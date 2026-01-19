SET search_path TO cms;

CREATE TABLE categories (
    -- I. ĐỊNH DANH & CẤU TRÚC
    _id UUID PRIMARY KEY, -- Khuyến nghị sinh UUID v7 từ Application
    tenant_id UUID NOT NULL,
    parent_id UUID,

    -- II. PHÂN LOẠI
    category_type VARCHAR(20) NOT NULL DEFAULT 'CONTENT',
    article_type VARCHAR(50), -- Gợi ý loại bài viết con (Optional)
    product_type VARCHAR(50), -- Gợi ý loại sản phẩm con (Optional)

    -- III. LIÊN KẾT TRANG (CMS Mapping)
    page_id UUID,        -- Trang Landing của Category
    detail_page_id UUID, -- Trang Template chi tiết cho các item con

    -- IV. NỘI DUNG & ĐỊNH TUYẾN
    code VARCHAR(50),
    name TEXT NOT NULL,
    slug VARCHAR(255) NOT NULL,
    full_slug TEXT NOT NULL, -- Materialized Path cho URL (VD: /san-pham/dien-thoai)
    path TEXT NOT NULL DEFAULT '/', -- Materialized Path cho ID (VD: /root_id/child_id/)
    level INT NOT NULL DEFAULT 1,

    translations JSONB NOT NULL DEFAULT '{}',
    settings JSONB NOT NULL DEFAULT '{}', -- Chứa SEO, Icon, Redirect URL...

    -- V. TRẠNG THÁI & THỐNG KÊ
    article_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    order_index INT NOT NULL DEFAULT 0,

    -- VI. AUDIT
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- RÀNG BUỘC (CONSTRAINTS)
    CONSTRAINT fk_cat_tenant FOREIGN KEY (tenant_id) REFERENCES core.tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES categories(_id) ON DELETE CASCADE,
    -- CONSTRAINT fk_cat_page FOREIGN KEY (page_id) REFERENCES pages(_id), -- Bỏ comment nếu bảng pages đã có
    -- CONSTRAINT fk_cat_detail_page FOREIGN KEY (detail_page_id) REFERENCES pages(_id),

    CONSTRAINT chk_cat_type CHECK (category_type IN ('CONTENT', 'PRODUCT', 'LINK', 'PAGE', 'GROUP')),
    CONSTRAINT chk_cat_slug CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT uq_cat_full_slug UNIQUE (tenant_id, full_slug), -- URL đầy đủ phải duy nhất trong 1 Tenant
    CONSTRAINT uq_cat_code UNIQUE (tenant_id, code) -- Mã danh mục duy nhất nếu có nhập
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- A. Index hỗ trợ Routing: Tìm danh mục nhanh nhất từ URL (Frontend)
-- Query: SELECT * FROM categories WHERE tenant_id = ? AND full_slug = ?
CREATE UNIQUE INDEX idx_categories_routing
ON categories (tenant_id, full_slug)
WHERE deleted_at IS NULL;

-- B. Index hỗ trợ lấy cây Menu (Frontend & Admin)
-- Sắp xếp theo cha-con và thứ tự ưu tiên
-- Query: SELECT * FROM categories WHERE tenant_id = ? AND parent_id = ? ORDER BY order_index
CREATE INDEX idx_categories_tree
ON categories (tenant_id, parent_id, order_index ASC)
WHERE deleted_at IS NULL;

-- C. Index hỗ trợ tìm kiếm cây con (Admin)
-- Sử dụng text_pattern_ops để tối ưu cho toán tử LIKE 'path/%'
CREATE INDEX idx_categories_path_search
ON categories (tenant_id, path text_pattern_ops)
WHERE deleted_at IS NULL;

-- D. Index hỗ trợ lọc theo loại (VD: Lấy tất cả danh mục sản phẩm)
CREATE INDEX idx_categories_type_filter
ON categories (tenant_id, category_type)
WHERE deleted_at IS NULL;

-- E. GIN Index cho cấu hình và đa ngôn ngữ
CREATE INDEX idx_categories_settings ON categories USING GIN (settings);
CREATE INDEX idx_categories_translations ON categories USING GIN (translations);



CREATE TABLE articles (
    _id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES core.tenants(_id) ON DELETE CASCADE,

    -- Phân loại & Tìm kiếm
    category_id UUID NOT NULL,
    extra_category_ids UUID[] DEFAULT '{}',
    all_category_ids UUID[] GENERATED ALWAYS AS (
        array_append(extra_category_ids, category_id)
    ) STORED,

    -- Nội dung cơ bản (Default Locale)
    title TEXT NOT NULL,
    slug VARCHAR(255) NOT NULL,
    summary TEXT,
    thumbnail_url TEXT,

    -- Đa ngôn ngữ (Phần nhẹ cho Listing)
    listing_translations JSONB NOT NULL DEFAULT '{}',
    available_locales TEXT[] NOT NULL DEFAULT '{}',

    -- Full-text Search
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(title, '') || ' ' || coalesce(summary, ''))
    ) STORED,

    -- Shadow & Sharing Logic
    sharing_policy VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    original_article_id UUID REFERENCES articles(_id), -- Self-referencing
    original_tenant_id UUID,

    -- Vận hành
    access_plans TEXT[] DEFAULT '{}',
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    workflow_status VARCHAR(20) DEFAULT 'DRAFT',

    published_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,

    -- Audit
    author_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uq_art_slug UNIQUE (tenant_id, slug),
    CONSTRAINT chk_art_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT chk_art_sharing CHECK (sharing_policy IN ('PRIVATE', 'TO_CHILDREN', 'TO_PARENT', 'GLOBAL'))
);

-- Indexing cho Articles
CREATE INDEX idx_articles_feed ON articles (tenant_id, status, published_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);
CREATE INDEX idx_articles_categories ON articles USING GIN (all_category_ids);
CREATE INDEX idx_articles_shadow ON articles (original_article_id) WHERE original_article_id IS NOT NULL;
CREATE INDEX idx_articles_locales ON articles USING GIN (available_locales);

CREATE TABLE article_details (
    article_id UUID PRIMARY KEY REFERENCES articles(_id) ON DELETE CASCADE,

    -- Nội dung (Default Locale)
    content_blocks JSONB NOT NULL DEFAULT '[]',

    -- Nội dung (Other Locales) - LƯU Ý: Tách riêng để không làm nặng bảng chính
    content_translations JSONB NOT NULL DEFAULT '{}',

    -- Metadata & Settings
    seo_metadata JSONB NOT NULL DEFAULT '{}',
    settings JSONB NOT NULL DEFAULT '{}', -- allow_comment, layout...

    updated_at TIMESTAMPTZ DEFAULT NOW()
);



ALTER TABLE articles
ADD COLUMN tag_ids UUID[] DEFAULT '{}';

-- Quan trọng: Tạo GIN Index để tìm kiếm bài viết theo Tag cực nhanh
-- Giúp query: Tìm tất cả bài viết có tag là 'CNTT'
CREATE INDEX idx_articles_tags
ON articles USING GIN (tag_ids);



CREATE OR REPLACE FUNCTION cascade_delete_shadow_articles()
RETURNS TRIGGER AS $$
BEGIN
    -- Xóa tất cả các bài viết Shadow đang trỏ vào bài vừa bị xóa
    DELETE FROM articles
    WHERE original_article_id = OLD._id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_articles_shadow_cleanup
AFTER DELETE ON articles
FOR EACH ROW
EXECUTE FUNCTION cascade_delete_shadow_articles();



CREATE TABLE article_versions (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID,
    tenant_id UUID NOT NULL,
    article_id UUID NOT NULL,

    -- II. METADATA PHIÊN BẢN
    version BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    editor_id UUID NOT NULL,
    change_reason TEXT,
    changed_fields TEXT[], -- Gợi ý: Dùng để hiển thị nhanh trên UI lịch sử

    -- III. SNAPSHOT DỮ LIỆU (Lưu trạng thái cũ)
    title TEXT NOT NULL,
    summary TEXT,
    content_blocks JSONB NOT NULL DEFAULT '[]', -- Nội dung chính

    -- Snapshot các dữ liệu phụ trợ quan trọng
    content_translations JSONB DEFAULT '{}',
    settings_snapshot JSONB DEFAULT '{}',

    -- IV. RÀNG BUỘC
    -- Composite Primary Key: Giúp gom nhóm các version của cùng 1 bài viết lại gần nhau
    -- _id vẫn là UUID v7 duy nhất, nhưng đứng sau để tận dụng Data Locality
    PRIMARY KEY (tenant_id, article_id, version DESC),

    CONSTRAINT fk_version_tenant FOREIGN KEY (tenant_id) REFERENCES core.tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_version_article FOREIGN KEY (article_id) REFERENCES articles(_id) ON DELETE CASCADE,
    CONSTRAINT chk_version_number CHECK (version >= 1)
);

-- 3. CHIẾN LƯỢC INDEX

-- Index hỗ trợ tìm kiếm phiên bản cụ thể theo ID (dù PK là composite)
CREATE UNIQUE INDEX idx_article_versions_id
ON article_versions (_id);

-- Index hỗ trợ việc dọn dẹp các phiên bản quá cũ (Retention Policy)
-- VD: Xóa các bản nháp cũ hơn 30 ngày
CREATE INDEX idx_article_versions_cleanup
ON article_versions (tenant_id, created_at)
WHERE version > 1; -- Thường giữ lại bản version 1 (gốc)





CREATE TABLE cms_banners (
    -- I. ĐỊNH DANH & LIÊN KẾT
    _id UUID PRIMARY KEY, -- Sinh UUID v7 từ Application Layer
    tenant_id UUID NOT NULL,
    zone_id UUID NOT NULL,

    -- II. NỘI DUNG & PHÂN LOẠI
    name TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'IMAGE',
    content_data JSONB NOT NULL DEFAULT '{}', -- Chứa Image URL, HTML Code, hoặc Slide Items
    click_url TEXT,
    priority INT NOT NULL DEFAULT 0,

    -- III. LỊCH TRÌNH & TRẠNG THÁI
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    start_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_at TIMESTAMPTZ,

    -- IV. THỐNG KÊ (Aggregated from ClickHouse)
    impressions BIGINT NOT NULL DEFAULT 0,
    clicks BIGINT NOT NULL DEFAULT 0,

    -- V. AUDIT & VERSIONING
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 1,

    -- VI. RÀNG BUỘC TOÀN VẸN
    CONSTRAINT fk_banner_tenant FOREIGN KEY (tenant_id) REFERENCES core.tenants(_id) ON DELETE CASCADE,
    CONSTRAINT fk_banner_zone FOREIGN KEY (zone_id) REFERENCES cms_banner_zones(_id) ON DELETE CASCADE,

    CONSTRAINT chk_banner_type CHECK (type IN ('IMAGE', 'HTML', 'SLIDER', 'VIDEO')),
    CONSTRAINT chk_banner_status CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED', 'SCHEDULED')),
    CONSTRAINT chk_banner_schedule CHECK (end_at IS NULL OR end_at > start_at),
    CONSTRAINT chk_banner_url CHECK (click_url IS NULL OR click_url ~* '^https?://')
);

-- 2. CHIẾN LƯỢC ĐÁNH INDEX (INDEXING STRATEGY)

-- Index quan trọng nhất: Phục vụ API lấy banner ra hiển thị (High Performance)
-- Logic: Lấy banner thuộc Zone X, đang Active, trong thời gian hiệu lực, sắp xếp theo ưu tiên
-- Query: SELECT * FROM cms_banners WHERE zone_id = ? AND status = 'ACTIVE' ...
CREATE INDEX idx_cms_banners_display
ON cms_banners (zone_id, status, start_at, end_at, priority DESC)
WHERE deleted_at IS NULL;

-- Index hỗ trợ trang quản trị (Admin CMS): Liệt kê banner của Tenant mới nhất lên đầu
CREATE INDEX idx_cms_banners_admin_list
ON cms_banners (tenant_id, created_at DESC)
WHERE deleted_at IS NULL;
