| Bảng | Tên trường (Field) | Kiểu dữ liệu | Null? | Mặc định (Default) | Ràng buộc (Constraints) & Logic Kiểm tra | Mô tả |
| ---- | ------------------ | ------------ | ----- | ------------------ | ---------------------------------------- | ----- |
| Tổ chức Nội dung (Content Organization) |  | Package |  |  |  |  |
| categories | YSQL | Collection |  |  |  | Quản lý cây danh mục phân cấp. |
| categories | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| categories | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Sharding Key. Xác định danh mục thuộc về khách hàng nào. |
| categories | parent\_id | UUID | YES | NULL | REFERENCES categories(\_id) ON DELETE CASCADE | ID danh mục cha. Hỗ trợ cấu trúc cây đa cấp. |
| categories | category\_type | VARCHAR(20) | NO | CONTENT' | CHECK (category\_type IN ('CONTENT', 'PRODUCT', 'LINK', 'PAGE', 'GROUP')) | Phân loại node: Nội dung, Sản phẩm, Liên kết ngoài, Trang đơn, hoặc Nhóm menu. |
| categories | page\_id | UUID | YES | NULL | REFERENCES pages(\_id) | Trang đích (Landing Page) hiển thị nội dung của danh mục này (nếu có). |
| categories | detail\_page\_id | UUID | YES | NULL | REFERENCES pages(\_id) | Trang mẫu (Template) dùng để hiển thị chi tiết các bài viết/sản phẩm con. |
| categories | code | VARCHAR(50) | YES | NULL | CHECK (code \~ '^[A-Z0-9\_]+$') | Mã định danh nghiệp vụ (VD: CAT\_NEWS\_01). Duy nhất trong Tenant. |
| categories | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên hiển thị mặc định của danh mục. |
| categories | slug | VARCHAR(255) | NO |  | CHECK (slug \~ '^[a-z0-9-]+$') | URL thân thiện (VD: tin-tuc). Duy nhất trong cùng cấp cha. |
| categories | full\_slug | TEXT | NO |  | UNIQUE(tenant\_id, full\_slug) | Đường dẫn URL đầy đủ (VD: san-pham/dien-thoai/iphone). Dùng để Routing. |
| categories | path | TEXT | NO | /' |  | Materialized Path (VD: /root\_id/child\_id/). Giúp truy vấn cây con cực nhanh. |
| categories | level | INT | NO | 1 | CHECK (level >= 1) | Độ sâu của danh mục trong cây (Level 1 là gốc). |
| categories | article\_type | VARCHAR(50) | YES | NULL |  | Loại bài viết mặc định cho danh mục này (VD: NEWS, BLOG). Chỉ dùng khi type=CONTENT. |
| categories | product\_type | VARCHAR(50) | YES | NULL |  | Loại sản phẩm mặc định cho danh mục này (VD: PHYSICAL, DIGITAL). Chỉ dùng khi type=PRODUCT. |
| categories | translations | JSONB | NO | {}' |  | Lưu tên/mô tả đa ngôn ngữ. VD: {"en": {"name": "News"}, "ja": {"name": "News"}}. |
| categories | settings | JSONB | NO | {}' |  | Cấu hình mở rộng (Icon, Color, Redirect URL, SEO Metadata). |
| categories | article\_count | INT | NO | 0 | CHECK (article\_count >= 0) | Cache số lượng bài viết/sản phẩm để hiển thị nhanh (Denormalization). |
| categories | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái bật/tắt hiển thị trên website. |
| categories | order\_index | INT | NO | 0 |  | Thứ tự sắp xếp hiển thị (Priority). Số nhỏ lên trên. |
| categories | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| categories | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| categories | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Soft Delete. Phục vụ khôi phục dữ liệu. |
| articles | YSQL | Collection |  |  |  | Bảng lõi lưu trữ nội dung bài viết (hỗ trợ 15 loại khác nhau). |
| articles | \_id | UUID | NO |  | PRIMARY KEY | UUID v7. |
| articles | tenant\_id | UUID | NO |  | FK -> tenants | Sharding Key. |
| articles | category\_id | UUID | NO |  | FK -> categories | Danh mục chính. |
| articles | extra\_category\_ids | UUID[] | NO | {}' |  | Danh mục phụ. |
| articles | all\_category\_ids | UUID[] | GEN |  | GENERATED STORED | Cột tính toán: Gộp chính + phụ để filter nhanh. |
| articles | title | TEXT | NO |  | CHECK (> 0) | Tiêu đề (Ngôn ngữ mặc định). |
| articles | slug | VARCHAR(255) | NO |  | UNIQUE(tenant\_id, slug) | URL thân thiện. |
| articles | summary | TEXT | YES |  |  | Sapo/Tóm tắt (Ngôn ngữ mặc định). |
| articles | thumbnail\_url | TEXT | YES |  |  | Ảnh đại diện. |
| articles | listing\_translations | JSONB | NO | {}' |  | JSON nhẹ: Chỉ chứa Title, Slug, Summary của các ngôn ngữ khác (VD: {"en": {"title": "..."}}). |
| articles | available\_locales | TEXT[] | GEN |  | GENERATED STORED | Cột tính toán: Tự động lấy key từ listing\_translations để filter ngôn ngữ. |
| articles | search\_vector | TSVECTOR | GEN |  | GENERATED STORED | Tìm kiếm: Vector từ Title + Summary. |
| articles | sharing\_policy | VARCHAR(20) | NO | PRIVATE' | PRIVATE, TO\_CHILDREN, TO\_PARENT | Chính sách chia sẻ bài viết. |
| articles | original\_article\_id | UUID | YES |  | FK -> articles | Shadow: ID bài gốc (nếu đây là bài được chia sẻ). |
| articles | access\_plans | TEXT[] | NO | {}' |  | Danh sách gói cước được xem (Paywall). |
|  | tag\_ids | UUID[] | YES |  |  | Lưu mảng các ID của tag (VD: ['uuid-1', 'uuid-2']). |
|  | tags\_cache | JSONB | YES |  |  | (Tùy chọn) Lưu snapshot tên và màu của tag để hiển thị ngay mà không cần lookup. |
| articles | status | VARCHAR(20) | NO | DRAFT' | DRAFT, PUBLISHED... | Trạng thái hiển thị. |
| articles | published\_at | TIMESTAMPTZ | YES |  |  | Thời gian xuất bản. |
| articles | version | BIGINT | NO | 1 |  | Optimistic Locking. |
| article\_details | YSQL | Collection |  |  |  | Nội dung chi tiết của bài viết |
| article\_details | article\_id | UUID | NO |  | PRIMARY KEY, FK -> articles(\_id) (Cascade Delete). |  |
| article\_details | content\_blocks | JSONB | NO | []' | Nội dung chính dạng Block (Editor.js) của ngôn ngữ mặc định. |  |
| article\_details | content\_translations | JSONB | NO | {}' | JSON nặng: Chứa content\_blocks của các ngôn ngữ khác. |  |
| article\_details | seo\_metadata | JSONB | NO | {}' | Meta title, description, og:image cho SEO. |  |
| article\_details | settings | JSONB | NO | {}' | Cấu hình: allow\_comment, template\_layout... |  |
| article\_details | audit\_log | JSONB | NO | []' | Lưu vết lịch sử sửa đổi ngắn gọn. |  |
| article\_versions | YSQL | Collection |  |  |  | Nội dung các phiên bản của bài viết |
| article\_versions | \_id | UUID | NO |  | PRIMARY KEY | Định danh phiên bản. Sử dụng UUID v7 để tối ưu sắp xếp theo thời gian [Source 1202]. |
| article\_versions | article\_id | UUID | NO |  | REFERENCES articles(\_id) ON DELETE CASCADE | Liên kết chặt chẽ với bài viết gốc. Nếu bài gốc bị xóa vĩnh viễn, lịch sử phiên bản cũng sẽ mất. |
| article\_versions | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Sharding Key để đảm bảo dữ liệu phiên bản nằm cùng node với bài viết gốc [Source 911]. |
| article\_versions | version | BIGINT | NO |  | CHECK (version >= 1) | Số thứ tự phiên bản (1, 2, 3...). Giá trị này được copy từ bảng articles tại thời điểm snapshot. |
| article\_versions | title | TEXT | NO |  |  | Tiêu đề bài viết tại thời điểm lưu phiên bản. |
| article\_versions | summary | TEXT | YES | NULL |  | Sapo/Tóm tắt tại thời điểm lưu phiên bản. |
| article\_versions | content\_blocks | JSONB | NO | []' |  | Quan trọng: Chứa toàn bộ nội dung bài viết (dạng Block Editor) tại thời điểm đó để phục vụ Rollback. |
| article\_versions | content\_translations | JSONB | NO | {}' |  | Lưu snapshot các bản dịch đa ngôn ngữ tại thời điểm đó (nếu có). |
| article\_versions | settings\_snapshot | JSONB | NO | {}' |  | Lưu cấu hình hiển thị tại thời điểm đó (đề phòng đổi template làm vỡ bài cũ). |
| article\_versions | changed\_fields | TEXT[] | YES | NULL |  | Mảng ghi nhận nhanh các trường bị thay đổi so với bản trước (VD: ['title', 'content']). |
| article\_versions | change\_reason | TEXT | YES | NULL |  | Lý do sửa đổi (VD: "Sửa lỗi chính tả", "Cập nhật số liệu"). |
| article\_versions | editor\_id | UUID | NO |  | REFERENCES users(\_id) | Người thực hiện thay đổi tạo ra phiên bản này [Source 1202]. |
| article\_versions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản lưu này. |
| tags | YSQL | Collection |  |  |  | Quản lý từ khóa/chủ đề (Flat taxonomy). |
| tags | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| tags | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định tag thuộc về tổ chức nào (SaaS Isolation). |
| tags | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên hiển thị của Tag (VD: "Công nghệ", "ReactJS"). |
| tags | slug | VARCHAR(100) | NO |  | UNIQUE(tenant\_id, slug), CHECK (slug \~ '^[a-z0-9-]+$') | Đường dẫn thân thiện URL. Duy nhất trong phạm vi 1 Tenant. |
| tags | description | TEXT | YES | NULL |  | Mô tả ý nghĩa của Tag (tốt cho SEO). |
| tags | color | VARCHAR(7) | YES | NULL | CHECK (color \~ '^#[A-Fa-f0-9]{6}$') | Mã màu Hex để hiển thị Badge (VD: #FF5733). |
| tags | metadata | JSONB | NO | {}' |  | Chứa thông tin mở rộng (VD: Icon, Custom grouping). |
| tags | usage\_count | BIGINT | NO | 0 | CHECK (usage\_count >= 0) | Cache: Số lượng bài viết/sản phẩm đang dùng tag này (Cập nhật Async). |
| tags | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo (UTC). |
| tags | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| tags | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking: Chống ghi đè khi nhiều Admin cùng sửa. |
| storage\_files | YSQL | Collection |  |  |  | Quản lý thư viện tài nguyên số (Ảnh, Video, Tài liệu). |
| storage\_files | \_id | UUID | NO |  | PRIMARY KEY | Định danh chuẩn UUID v7 giúp tối ưu sắp xếp theo thời gian và sharding. |
| storage\_files | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Sharding Key. Xác định file thuộc sở hữu của tổ chức nào. |
| storage\_files | parent\_id | UUID | YES | NULL |  | ID của thư mục chứa file (nếu có tính năng Media Folder). |
| storage\_files | original\_name | TEXT | NO |  | CHECK (length(original\_name) > 0) | Tên gốc của file khi người dùng upload. |
| storage\_files | storage\_path | TEXT | NO |  | UNIQUE(tenant\_id, storage\_path) | Đường dẫn (Key) lưu trên S3 (VD: tenant\_1/2023/10/img\_01.jpg). Không lưu domain ở đây. |
| storage\_files | public\_url | TEXT | YES | NULL |  | URL đầy đủ (CDN) nếu file được public. |
| storage\_files | mime\_type | VARCHAR(100) | NO |  |  | Loại file (VD: image/jpeg, video/mp4, application/pdf). |
| storage\_files | file\_size | BIGINT | NO | 0 | CHECK (file\_size >= 0) | Kích thước file (bytes) để thống kê dung lượng sử dụng (Metering). |
| storage\_files | dimensions | JSONB | NO | {}' |  | Lưu chiều rộng, chiều cao, độ dài video (VD: {"width": 1920, "height": 1080, "duration": 12.5}). |
| storage\_files | alt\_text | TEXT | YES | NULL |  | Văn bản thay thế (phục vụ SEO và Accessibility). |
| storage\_files | caption | TEXT | YES | NULL |  | Chú thích hiển thị dưới ảnh. |
| storage\_files | variants | JSONB | NO | {}' |  | Lưu thông tin các phiên bản đã resize/optimize (Thumbnail, Small, Medium). |
| storage\_files | metadata | JSONB | NO | {}' |  | Dữ liệu kỹ thuật mở rộng (EXIF, Focus point, Dominant color, AI tags). |
| storage\_files | storage\_provider | VARCHAR(20) | NO | S3' | CHECK (IN ('S3', 'R2', 'MINIO', 'CLOUDFLARE')) | Nơi lưu trữ vật lý (Hỗ trợ Multi-cloud strategy). |
| storage\_files | visibility | VARCHAR(20) | NO | PRIVATE' | CHECK (IN ('PUBLIC', 'PRIVATE', 'INTERNAL')) | Quyền truy cập: Public (CDN), Private (Signed URL). |
| storage\_files | status | VARCHAR(20) | NO | PROCESSING' | CHECK (IN ('UPLOADING', 'PROCESSING', 'READY', 'FAILED')) | Trạng thái xử lý file (nếu cần resize/transcode video). |
| storage\_files | uploaded\_by | UUID | YES | NULL | REFERENCES users(\_id) | Người thực hiện upload. |
| storage\_files | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi. |
| storage\_files | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| storage\_files | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Soft Delete (Giữ metadata một thời gian trước khi xóa file trên S3). |
| storage\_files | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking. |
| cms\_comments | YSQL | Collection |  |  |  | Quản lý tương tác người dùng (hỗ trợ phân cấp). |
