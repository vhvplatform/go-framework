| Bảng | Tên trường (Field) | Kiểu dữ liệu | Null? | Mặc định (Default) | Ràng buộc (Constraints) & Logic Kiểm tra | Mô tả |
| ---- | ------------------ | ------------ | ----- | ------------------ | ---------------------------------------- | ----- |
| CORE & IDENTITY (HẠ TẦNG & ĐỊNH DANH) |  | Package |  |  |  |  |
| Nhóm Định danh và Tổ chức Cốt lõi (Core Foundation) |  | Package |  |  |  | Nhóm này quản lý danh tính con người và cấu trúc pháp nhân của khách hàng |
| tenants | YSQL | Collection |  |  |  | Lưu thông tin khách hàng, định danh (\_id, code), ràng buộc vùng (data\_region) và cấu hình gốc. |
| tenants | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| tenants | code | VARCHAR(64) | NO |  | UNIQUE, CHECK (code \~ '^[a-z0-9-]+$') | Mã định danh (Slug/Subdomain). Chỉ chứa chữ thường, số, gạch ngang. |
| tenants | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên hiển thị chính thức của công ty. |
| tenants | data\_region | VARCHAR(50) | NO | ap-southeast-1' | CHECK (data\_region IN ('ap-southeast-1', 'us-east-1', 'eu-central-1')) | Vị trí vật lý lưu trữ dữ liệu (Geo-Partitioning) để tuân thủ pháp lý. |
| tenants | parent\_tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | ID của công ty mẹ hoặc đối tác phân phối cấp trên. |
| tenants | path | TEXT | YES |  | BTREE INDEX | Materialized Path (VD: /mẹ/con/) giúp truy vấn cây đối tác cực nhanh. |
| tenants | compliance\_level | VARCHAR(20) | NO | STANDARD' | CHECK (compliance\_level IN ('STANDARD', 'GDPR', 'HIPAA', 'PCI-DSS')) | Mức độ tuân thủ bảo mật, quyết định quy trình xử lý dữ liệu. |
| tenants | tier | VARCHAR(50) | NO | FREE' | CHECK (tier IN (<br><br>'FREE', 'PRO', 'ENTERPRISE', -- Khách hàng cuối<br>'PARTNER\_BASIC', 'PARTNER\_PREMIUM', 'PARTNER\_ELITE', -- Đối tác<br>'PROVIDER' -- Chủ nền tảng<br>)) | Cấp độ gói dịch vụ (VD: FREE, PRO, ENTERPRISE). |
| tenants | billing\_type | VARCHAR(20) | NO | POSTPAID' | CHECK (billing\_type IN ('PREPAID', 'POSTPAID')) | Hình thức thanh toán: Trả trước hoặc trả sau. |
| tenants | timezone | VARCHAR(50) | NO | UTC' |  | Múi giờ hành chính để tính toán thời hạn gói và báo cáo. |
| tenants | profile | JSONB | NO | {}' |  | Thông tin thương hiệu và bộ nhận diện (Metadata hiển thị).<br><br>1\. Thông tin thương hiệu và nhận diện \(Branding\)<br>Đây là nhóm thông tin chính dùng để cá nhân hóa giao diện người dùng (UI/UX) cho từng khách hàng doanh nghiệp:<br>• description: Mô tả ngắn gọn về hoạt động kinh doanh hoặc giới thiệu về công ty,. Thông tin này thường hiển thị trên trang hồ sơ công khai hoặc trang quản trị nội bộ.<br>• logo\_url: Đường dẫn đến tệp ảnh logo của công ty,. Do các URL này có thể rất dài (đặc biệt khi sử dụng Presigned URL từ S3 hoặc các dịch vụ CDN), việc lưu trong JSONB giúp linh hoạt hơn so với các cột VARCHAR giới hạn,.<br>• website\_url (hoặc website): Địa chỉ trang chủ chính thức của doanh nghiệp,.<br>2\. Thông tin pháp lý và thuế \(Tax & Legal\)<br>Nhóm này lưu trữ các dữ liệu cần thiết cho việc xuất hóa đơn hoặc xác minh danh tính doanh nghiệp mà không cần tạo quá nhiều cột rời rạc:<br>• tax\_info: Một đối tượng lồng nhau (nested object) bao gồm:<br>◦ tax\_code: Mã số thuế của doanh nghiệp,.<br>◦ address: Địa chỉ pháp lý đăng ký trên giấy phép kinh doanh (khác với địa chỉ văn phòng thực tế có thể thay đổi),.<br>3\. Liên kết mạng xã hội \(Social Links\)<br>Trường profile cho phép lưu trữ không giới hạn các liên kết mạng xã hội tùy theo nhu cầu của từng Tenant:<br>• socials (hoặc social\_links): Một đối tượng chứa các khóa như:<br>◦ facebook: Link trang Fanpage.<br>◦ linkedin: Link hồ sơ doanh nghiệp trên LinkedIn.<br>◦ twitter, tiktok, hoặc các nền tảng khác phát sinh sau này,.<br>4\. Các thuộc tính tùy biến khác<br>Vì tính chất schema-less của JSONB, trường profile có thể mở rộng thêm các thuộc tính mà không cần sửa đổi cấu trúc bảng (ALTER TABLE),:<br>• industry: Ngành nghề kinh doanh cụ thể.<br>• founded\_year: Năm thành lập.<br>• contact\_person: Thông tin người liên hệ bổ sung (nếu không nằm trong các bảng chuyên biệt). |
| tenants | settings | JSONB | NO | {}' |  | Cấu hình vận hành và chính sách bảo mật (Metadata logic).<br><br>1\. Chính sách bảo mật \(Security Policies\)<br>Đây là nhóm thuộc tính quan trọng nhất, giúp thực thi các tiêu chuẩn an ninh khắt khe của doanh nghiệp.<br>• password\_policy: Đối tượng cấu hình mật khẩu, bao gồm:<br>◦ min\_length: Độ dài tối thiểu của mật khẩu (thường >= 8).<br>◦ require\_special\_char: Bắt buộc mật khẩu có ký tự đặc biệt.<br>◦ expiry\_days: Số ngày mật khẩu hết hạn (0 là không bao giờ).<br>◦ history\_limit: Số lượng mật khẩu cũ không được phép trùng lại.<br>• mfa\_enforced: Cờ BOOLEAN bắt buộc tất cả người dùng thuộc Tenant này phải bật xác thực 2 yếu tố (MFA).<br>• ip\_whitelist (hoặc allowed\_ip\_ranges): Mảng chứa các dải địa chỉ IP (CIDR) được phép truy cập vào hệ thống.<br>• session\_policy: Cấu hình phiên làm việc:<br>◦ timeout\_minutes: Thời gian tự động đăng xuất khi không hoạt động.<br>◦ max\_login\_attempts: Số lần thử sai tối đa trước khi khóa tài khoản.<br>2\. Cấu hình vận hành và Hạ tầng \(Operational & Infrastructure\)<br>Nhóm này quy định cách hệ thống xử lý dữ liệu và định tuyến cho Tenant.<br>• compliance: Mức độ tuân thủ bảo mật (ví dụ: GDPR, HIPAA, PCI-DSS), quyết định quy trình xóa vĩnh viễn hoặc lưu vết dữ liệu.<br>• data\_residency: Quy định vùng địa lý lưu trữ dữ liệu để đảm bảo tuân thủ luật pháp quốc gia (ví dụ: ap-southeast-1).<br>• rate\_limiting: Hạn ngạch gọi API cho từng Tenant để chống DDoS nội bộ và quá tải hệ thống.<br>◦ requests\_per\_minute: Số lượng request tối đa trong một phút.<br>◦ burst\_size: Số lượng request tối đa cho phép bùng phát trong thời gian ngắn.<br>3\. Chính sách lưu trữ và Phê duyệt \(Governance\)<br>Dành cho các yêu cầu quản trị chuyên sâu của khách hàng Enterprise.<br>• archival\_policy: Quy định thời gian dữ liệu được giữ lại trong DB trước khi đẩy vào kho lưu trữ lạnh (S3).<br>◦ audit\_log\_retention\_days: Số ngày lưu giữ nhật ký truy vết.<br>◦ invoice\_retention\_days: Số ngày lưu giữ hóa đơn trong hệ thống.<br>• approval\_required: Cờ bắt buộc các hành động nhạy cảm (như xóa dữ liệu, xuất file) phải qua quy trình phê duyệt (Maker-Checker). |
| tenants | status | VARCHAR(20) | NO | TRIAL' | CHECK (status IN ('TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED')) | Trạng thái vòng đời của tenant. |
| tenants | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| tenants | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| tenants | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Cờ xóa mềm (Soft Delete) phục vụ truy vết và khôi phục. |
| tenants | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè dữ liệu đồng thời. |
| tenants | active\_apps | TEXT[] | YES | NULL |  | Cache danh sách App. Mảng chứa mã các ứng dụng mà tenant có quyền truy cập để API Gateway kiểm tra nhanh. |
| tenants | metadata | JSONB | NO | {}' |  | Lưu trữ linh hoạt các thông tin profile như Logo, Website, Tax Code hoặc các thuộc tính tùy chỉnh. |
| applications | YSQL | Collection |  |  |  | định nghĩa các đơn vị phần mềm kỹ thuật cụ thể (ví dụ: App Tuyển dụng, App Chấm công) trước khi được đóng gói thành các gói cước thương mại (service\_packages) |
| applications | \_id | UUID | NO | - | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| applications | code | VARCHAR(50) | NO | - | UNIQUE, CHECK (code \~ '^[A-Z0-9\_]+$') | Mã định danh kỹ thuật (VD: HRM\_RECRUIT). Chỉ chứa chữ hoa, số và gạch dưới. |
| applications | name | VARCHAR(255) | NO | - | CHECK (LENGTH(name) > 0) | Tên hiển thị của ứng dụng trên giao diện. |
| applications | description | TEXT | YES | NULL | - | Mô tả chi tiết về chức năng kỹ thuật của ứng dụng. |
| applications | is\_active | BOOLEAN | NO | TRUE | - | Trạng thái bật/tắt ứng dụng trên toàn hệ thống. |
| applications | created\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm tạo bản ghi ứng dụng. |
| applications | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật dữ liệu gần nhất. |
| applications | deleted\_at | TIMESTAMPTZ | YES | NULL | - | Thời điểm xóa mềm (Soft Delete) để bảo toàn dữ liệu lịch sử. |
| applications | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking, ngăn chặn ghi đè dữ liệu đồng thời. |
| users | YSQL | Collection |  |  |  | Lưu trữ thông tin định danh toàn cục của một con người thực (Email, Password Hash, Avatar). Đây là bảng duy nhất chứa thông tin đăng nhập trên toàn sàn. |
| users | \_id | UUID | NO | - | PRIMARY KEY | Định danh duy nhất toàn cục chuẩn UUID v7,. |
| users | email | VARCHAR(255) | NO | - | UNIQUE, CHECK (email \~\* '^[A-Za-z0-9.\_%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') | Email đăng nhập chính. Phải là duy nhất trên toàn hệ thống và đúng định dạng,. |
| users | password\_hash | TEXT | YES | NULL | - | Chuỗi băm mật khẩu (Argon2id/Bcrypt). Để NULL nếu dùng Social Login/SSO. Dùng TEXT để không giới hạn độ dài thuật toán,. |
| users | full\_name | TEXT | NO | - | CHECK (LENGTH(full\_name) > 0) | Tên hiển thị mặc định của người dùng,. |
| users | phone\_number | VARCHAR(20) | YES | NULL | UNIQUE | Số điện thoại cá nhân dùng cho xác thực 2 lớp (MFA) hoặc khôi phục tài khoản,. |
| users | avatar\_url | TEXT | YES | NULL | CHECK (avatar\_url \~\* '^https?://') | Đường dẫn ảnh đại diện (Presigned URL),. |
| users | status | VARCHAR(20) | NO | ACTIVE' | CHECK (status IN ('ACTIVE', 'BANNED', 'DISABLED', 'PENDING')) | Trạng thái tài khoản toàn sàn. BANNED là cấm truy cập toàn bộ hệ thống,. |
| users | is\_support\_staff | BOOLEAN | NO | FALSE | - | Đánh dấu nhân viên hỗ trợ của nhà cung cấp SaaS để kích hoạt tính năng Impersonation (giả mạo),. |
| users | mfa\_enabled | BOOLEAN | NO | FALSE | - | Trạng thái bật/tắt xác thực đa yếu tố. |
| users | mfa\_secret | TEXT | YES | NULL | - | Secret key cho TOTP (Google Authenticator), cần mã hóa khi lưu,. |
| users | is\_verified | BOOLEAN | NO | FALSE | - | Đánh dấu email đã được xác thực chính chủ hay chưa. |
| users | locale | VARCHAR(10) | NO | vi-VN' | - | Ngôn ngữ và định dạng hiển thị ưa thích. |
| users | metadata | JSONB | NO | {}' | - | Lưu thông tin tùy chỉnh (Sở thích, cấu hình cá nhân). |
| users | created\_at | TIMESTAMPTZ | NO | now() | - | Thời điểm tạo tài khoản (UTC). |
| users | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật thông tin gần nhất. |
| users | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Soft Delete: Nếu khác NULL, tài khoản coi như đã bị xóa nhưng vẫn giữ dữ liệu cho mục đích đối soát (Audit). |
| tenant\_members | YSQL | Collection |  |  |  | Bảng liên kết người dùng với tổ chức. Nó lưu hồ sơ nhân viên, mã nhân viên, chức danh và trạng thái làm việc tại một công ty cụ thể. |
| tenant\_members | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tối ưu sắp xếp và chèn dữ liệu. |
| tenant\_members | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) | Xác định thành viên thuộc tổ chức nào. Là Sharding Key quan trọng. |
| tenant\_members | user\_id | UUID | NO |  | REFERENCES users(\_id) | Liên kết với danh tính người dùng toàn cục. |
| tenant\_members | display\_name | VARCHAR(255) | YES |  |  | Tên hiển thị riêng trong tổ chức (VD: "Anh An IT"). |
| tenant\_members | status | VARCHAR(20) | NO | INVITED' | CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'RESIGNED')) | Trạng thái hoạt động của thành viên trong tổ chức này. |
| tenant\_members | custom\_data | JSONB | NO | {}' |  | Lưu trữ linh hoạt các trường động (Mã NV, chức danh, size áo...). |
| tenant\_members | joined\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm chính thức gia nhập tổ chức. |
| tenant\_members | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi hồ sơ. |
| tenant\_members | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật hồ sơ gần nhất. |
| tenant\_members | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Soft Delete. Thời điểm xóa thành viên khỏi tổ chức. |
| tenant\_members | created\_by | UUID | YES |  |  | ID người thực hiện tạo hồ sơ (Admin/System). |
| tenant\_members | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking. Chống ghi đè dữ liệu khi nhiều Admin cùng sửa. |
| Nhóm Cơ cấu và Nhóm (Organization & Structure) |  | Package |  |  |  | Giúp phản ánh cấu trúc thực tế của doanh nghiệp |
| departments | YSQL | Collection |  |  |  | Quản lý cây phòng ban theo phân cấp (Hierarchy) sử dụng phương pháp Materialized Path để truy vấn nhanh |
| departments | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (UUID v7). Tối ưu hóa việc sắp xếp theo thời gian và tránh Hotspot,. |
| departments | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) | Xác định phòng ban thuộc tổ chức nào (Sharding Key quan trọng),. |
| departments | parent\_id | UUID | YES | NULL | REFERENCES departments(\_id) | ID của phòng ban cha. Dùng để xây dựng quan hệ phân cấp,. |
| departments | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên phòng ban (VD: Khối Công nghệ, Phòng Nhân sự). |
| departments | code | VARCHAR(50) | YES | NULL |  | Mã phòng ban dùng để đồng bộ với hệ thống ERP bên ngoài. |
| departments | type | VARCHAR(20) | NO | TEAM' | CHECK (type IN ('DIVISION', 'DEPARTMENT', 'TEAM')) | Phân loại cấp độ tổ chức,. |
| departments | head\_member\_id | UUID | YES | NULL | REFERENCES tenant\_members(\_id) | Trưởng phòng (Administrative Head). Link tới hồ sơ thành viên,. |
| departments | path | TEXT | YES |  |  | Materialized Path (VD: /root/dept\_a/team\_b/). Giúp truy vấn toàn bộ cây con cực nhanh,. |
| departments | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC),. |
| departments | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng,. |
| departments | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Soft Delete. Nếu khác NULL, phòng ban coi như đã bị giải thể,. |
| departments | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking. Ngăn chặn việc cập nhật dữ liệu đồng thời bị xung đột,. |
| department\_members | YSQL | Collection |  |  |  | Phân bổ nhân sự vào các phòng ban (quan hệ N-N) |
| department\_members | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" trong hệ thống phân tán. |
| department\_members | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) | Xác định bản ghi thuộc tổ chức nào (Sharding Key quan trọng). |
| department\_members | department\_id | UUID | NO |  | REFERENCES departments(\_id) | Liên kết tới phòng ban cụ thể. |
| department\_members | member\_id | UUID | NO |  | REFERENCES tenant\_members(\_id) | Liên kết tới hồ sơ nhân sự trong Tenant. |
| department\_members | is\_primary | BOOLEAN | NO | FALSE |  | Đánh dấu đây có phải là phòng ban chính của nhân sự này không (dùng để tính headcount). |
| department\_members | role\_in\_dept | VARCHAR(100) | YES | NULL |  | Vai trò cụ thể trong phòng ban này (VD: Thư ký, Điều phối viên). |
| department\_members | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm nhân sự được gán vào phòng ban (UTC). |
| department\_members | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật hồ sơ gần nhất. |
| user\_groups | YSQL | Collection |  |  |  | Quản lý các nhóm làm việc ngang hàng, dự án hoặc squad. Có thể thiết lập nhóm tĩnh hoặc nhóm động (Dynamic Groups) theo quy tắc |
| user\_groups | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (khuyến nghị dùng UUID v7 để tối ưu sắp xếp theo thời gian),. |
| user\_groups | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định nhóm thuộc tổ chức nào (Sharding Key quan trọng),. |
| user\_groups | parent\_id | UUID | YES | NULL | REFERENCES user\_groups(\_id) | ID của nhóm cha, dùng để xây dựng cấu trúc phân cấp lồng nhau,. |
| user\_groups | name | VARCHAR(100) | NO |  | CHECK (LENGTH(name) > 0) | Tên nhóm (VD: "Squad Mobile", "Phòng IT"). |
| user\_groups | code | VARCHAR(50) | YES | NULL |  | Mã định danh duy nhất trong một tenant (VD: GRP\_DEV\_01). |
| user\_groups | type | VARCHAR(20) | NO | CUSTOM' | CHECK (type IN ('ORG\_UNIT', 'PROJECT', 'PERMISSION', 'CUSTOM')) | Phân loại: Phòng ban, Dự án, Nhóm quyền hoặc nhóm tùy chỉnh. |
| user\_groups | dynamic\_rules | JSONB | YES | NULL |  | Quy tắc để tự động thêm thành viên (VD: {"dept": "IT", "loc": "HN"}),. |
| user\_groups | path | TEXT | YES | NULL |  | Materialized Path (VD: /root-id/child-id/) giúp truy vấn cây nhóm cực nhanh,. |
| user\_groups | description | TEXT | YES | NULL |  | Mô tả chi tiết về mục đích của nhóm. |
| user\_groups | owner\_member\_id | UUID | YES | NULL | REFERENCES tenant\_members(\_id) | ID người quản trị/trưởng nhóm,. |
| user\_groups | created\_at | TIMESTAMPTZ | NO | NOW() |  | Thời điểm tạo nhóm (UTC),. |
| user\_groups | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời,. |
| group\_members | YSQL | Collection |  |  |  | Danh sách thành viên trong các nhóm tĩnh |
| group\_members | YSQL | Collection | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp sắp xếp theo thời gian. |
| group\_members | YSQL | Collection | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định thành viên nhóm thuộc tổ chức nào (Sharding Key). |
| group\_members | YSQL | Collection | NO |  | REFERENCES user\_groups(\_id) ON DELETE CASCADE | Liên kết với nhóm (Squad, Dự án, Phòng ban). |
| group\_members | YSQL | Collection | NO |  | REFERENCES tenant\_members(\_id) ON DELETE CASCADE | Liên kết với hồ sơ nhân sự cụ thể trong Tenant. |
| group\_members | YSQL | Collection | NO | MEMBER' | CHECK (role\_in\_group IN ('LEADER', 'MEMBER', 'SECRETARY')) | Vai trò cụ thể của thành viên trong nhóm này. |
| group\_members | YSQL | Collection | NO | now() |  | Thời điểm thành viên gia nhập nhóm. |
| group\_members | YSQL | Collection | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| group\_members | YSQL | Collection | NO | 1 | CHECK (version >= 1) | Optimistic Locking: Ngăn chặn ghi đè dữ liệu khi nhiều Admin cùng thao tác. |
| location\_types | YSQL | Collection |  |  |  |  |
| location\_types | \_id | UUID | NO | - | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 [Conversation History]. |
| location\_types | tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | Liên kết tới Tenant. Nếu NULL, đây là loại địa điểm mặc định của hệ thống (System Type). |
| location\_types | code | VARCHAR(50) | NO | - | CHECK (code \~ '^[A-Z0-9\_]+$') | Mã kỹ thuật (VD: WAREHOUSE, POS\_STORE). Chỉ chứa chữ hoa, số và gạch dưới. |
| location\_types | name | TEXT | NO | - | CHECK (length(name) > 0) | Tên hiển thị (VD: "Kho lạnh", "Cửa hàng tiện lợi"). |
| location\_types | description | TEXT | YES | NULL | - | Mô tả chi tiết về loại địa điểm này. |
| location\_types | extra\_fields | JSONB | NO | []' | - | Schema Definition: Định nghĩa danh sách các trường động cần có cho loại này (Xem ví dụ bên dưới). |
| location\_types | is\_system | BOOLEAN | NO | FALSE | - | Nếu TRUE, Tenant không thể sửa hoặc xóa (Dữ liệu nền tảng). |
| location\_types | is\_active | BOOLEAN | NO | TRUE | - | Trạng thái sử dụng. |
| location\_types | created\_at | TIMESTAMPTZ | NO | now() | - | Thời điểm tạo bản ghi (UTC). |
| location\_types | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| location\_types | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking để ngăn chặn ghi đè cấu hình đồng thời. |
| locations | YSQL | Collection |  |  |  | Quản lý các địa điểm vật lý, văn phòng hoặc chi nhánh của Tenant |
| locations | \_id | UUID | NO | - | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| locations | tenant\_id | UUID | NO | - | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định địa điểm thuộc tổ chức nào (Sharding Key). |
| locations | parent\_id | UUID | YES | NULL | REFERENCES locations(\_id) | ID địa điểm cha. Dùng để xây dựng cấu trúc cây (Vùng -> Chi nhánh -> Phòng). |
| locations | type\_id | UUID | NO | - | REFERENCES location\_types(\_id) | Tham chiếu đến loại địa điểm để xác định schema của metadata [Conversation]. |
| locations | name | TEXT | NO | - | CHECK (LENGTH(name) > 0) | Tên hiển thị (VD: Kho tổng Cầu Giấy). |
| locations | code | VARCHAR(50) | YES | NULL | UNIQUE(tenant\_id, code) | Mã địa điểm dùng để đồng bộ với ERP/Máy chấm công. |
| locations | path | TEXT | YES | NULL | Index text\_pattern\_ops | Materialized Path (VD: /root-id/branch-id/). Giúp truy vấn toàn bộ nhánh con cực nhanh. |
| locations | status | VARCHAR(20) | NO | ACTIVE' | CHECK (IN ('ACTIVE', 'INACTIVE', 'CLOSED')) | Trạng thái hoạt động. |
| locations | address | JSONB | NO | {}' | - | Địa chỉ chi tiết chuẩn hóa (đường, phường, quận, thành phố). |
| locations | coordinates | POINT | YES | NULL | - | Tọa độ GPS (Kinh độ, Vĩ độ) dùng cho chấm công/định vị. |
| locations | radius\_meters | INT | YES | 100 | CHECK (radius\_meters > 0) | Bán kính cho phép chấm công xung quanh tọa độ (mét). |
| locations | timezone | VARCHAR(50) | NO | UTC' | - | Múi giờ địa phương (VD: Asia/Ho\_Chi\_Minh), quan trọng để tính ca làm việc. |
| locations | is\_headquarter | BOOLEAN | NO | FALSE | - | Đánh dấu trụ sở chính của Tenant. |
| locations | metadata | JSONB | NO | {}' | - | Dữ liệu động: Chứa các giá trị tương ứng với cấu hình extra\_fields của location\_types [Conversation]. |
| locations | created\_at | TIMESTAMPTZ | NO | now() | - | Thời điểm tạo bản ghi. |
| locations | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| locations | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking. |
| Nhóm Xác thực và Bảo mật (Authentication & Security) |  | Package |  |  |  | Đáp ứng các tiêu chuẩn bảo mật hiện đại như MFA và Passwordless |
| user\_linked\_identities | YSQL | Collection |  |  |  | Quản lý đa phương thức đăng nhập (Password, Google, GitHub, Microsoft) liên kết với một tài khoản người dùng. |
| user\_linked\_identities | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sắp xếp theo thời gian và sharding. |
| user\_linked\_identities | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến hồ sơ người dùng gốc trong bảng users. |
| user\_linked\_identities | provider | VARCHAR(20) | NO |  | CHECK (provider IN ('LOCAL', 'GOOGLE', 'GITHUB', 'MICROSOFT', 'APPLE', 'PASSKEY')) | Nguồn định danh (LOCAL là mật khẩu truyền thống, còn lại là OAuth/SSO). |
| user\_linked\_identities | provider\_id | VARCHAR(255) | NO |  | UNIQUE(provider, provider\_id) | ID định danh tại nguồn (Email đối với LOCAL, Subject ID đối với OAuth). |
| user\_linked\_identities | password\_hash | TEXT | YES | NULL |  | Lưu chuỗi băm mật khẩu (chỉ sử dụng khi provider = 'LOCAL'). |
| user\_linked\_identities | data | JSONB | NO | {}' |  | Lưu trữ linh hoạt metadata như: access\_token, refresh\_token, profile\_url từ nhà cung cấp. |
| user\_linked\_identities | last\_login\_at | TIMESTAMPTZ | YES | NULL |  | Ghi nhận thời điểm cuối cùng đăng nhập bằng phương thức này. |
| user\_linked\_identities | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm liên kết phương thức đăng nhập này vào tài khoản. |
| user\_sessions | YSQL | Collection |  |  |  | Quản lý phiên làm việc thực tế, thiết bị, IP và hỗ trợ cơ chế xoay vòng token (Rotation). |
| user\_sessions | \_id | UUID | NO |  | PRIMARY KEY | Định danh phiên (Session ID). Sử dụng UUID v7 để tối ưu sharding và sắp xếp theo thời gian. |
| user\_sessions | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) | Xác định phiên thuộc tổ chức nào (SaaS Isolation). |
| user\_sessions | user\_id | UUID | NO |  | REFERENCES users(\_id) | Liên kết tới người dùng sở hữu phiên. |
| user\_sessions | family\_id | UUID | NO |  |  | Định danh chuỗi token (Family). Dùng để thu hồi toàn bộ chuỗi nếu phát hiện token bị trộm. |
| user\_sessions | refresh\_token\_hash | VARCHAR(255) | YES | NULL |  | Lưu chuỗi băm của Refresh Token hiện tại để thực hiện cơ chế xoay vòng. |
| user\_sessions | rotation\_counter | INT | NO | 0 | CHECK (rotation\_counter >= 0) | Số lần xoay vòng token. Nếu phát hiện dùng lại counter thấp, hệ thống sẽ hủy cả family. |
| user\_sessions | ip\_address | INET | YES |  |  | Địa chỉ IP của thiết bị đăng nhập. |
| user\_sessions | user\_agent | TEXT | YES |  |  | Thông tin trình duyệt và hệ điều hành (Fingerprint). |
| user\_sessions | device\_type | VARCHAR(20) | YES |  |  | Phân loại thiết bị: MOBILE, DESKTOP, TABLET. |
| user\_sessions | location\_city | VARCHAR(100) | YES |  |  | Thành phố đăng nhập (GeoIP). |
| user\_sessions | is\_revoked | BOOLEAN | NO | FALSE |  | Trạng thái bị thu hồi. Nếu TRUE, phiên không còn hiệu lực (dùng cho tính năng "Đăng xuất từ xa"). |
| user\_sessions | expires\_at | TIMESTAMPTZ | NO |  |  | Thời điểm phiên hết hạn hoàn toàn. |
| user\_sessions | last\_active\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cuối cùng phiên có hoạt động. |
| user\_sessions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm bắt đầu phiên đăng nhập. |
| user\_mfa\_methods | YSQL | Collection |  |  |  | Lưu trữ các phương thức xác thực đa yếu tố (TOTP, SMS, Email). |
| user\_mfa\_methods | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (Sử dụng UUID v7 để tối ưu sharding và sắp xếp theo thời gian). |
| user\_mfa\_methods | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến người dùng sở hữu phương thức MFA này. |
| user\_mfa\_methods | type | VARCHAR(20) | NO |  | CHECK (type IN ('TOTP', 'SMS', 'EMAIL', 'HARDWARE')) | Loại xác thực: TOTP (App), SMS, Email hoặc khóa cứng. |
| user\_mfa\_methods | name | VARCHAR(50) | YES | NULL |  | Tên gợi nhớ cho thiết bị (VD: "iPhone 15 của An"). |
| user\_mfa\_methods | encrypted\_secret | TEXT | NO |  |  | Chuỗi bí mật (Secret Key) đã được mã hóa trước khi lưu để đảm bảo an toàn. |
| user\_mfa\_methods | is\_default | BOOLEAN | NO | FALSE |  | Đánh dấu phương thức ưu tiên khi đăng nhập. |
| user\_mfa\_methods | last\_used\_at | TIMESTAMPTZ | YES | NULL |  | Ghi lại thời điểm cuối cùng phương thức này được sử dụng. |
| user\_mfa\_methods | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm đăng ký phương thức MFA này. |
| user\_webauthn\_credentials | YSQL | Collection |  |  |  | Hỗ trợ đăng nhập bằng vân tay, FaceID hoặc khóa vật lý (Passkeys/FIDO2). |
| user\_webauthn\_credentials | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (Sử dụng UUID v7 để tối ưu sắp xếp theo thời gian và phân tán dữ liệu),. |
| user\_webauthn\_credentials | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến tài khoản người dùng gốc. |
| user\_webauthn\_credentials | name | VARCHAR(100) | YES | NULL |  | Tên gợi nhớ cho thiết bị (VD: "MacBook TouchID", "YubiKey 5C"). |
| user\_webauthn\_credentials | credential\_id | TEXT | NO |  | UNIQUE | ID định danh duy nhất của thiết bị WebAuthn trả về, dùng để nhận diện thiết bị khi đăng nhập,. |
| user\_webauthn\_credentials | public\_key | TEXT | NO |  |  | Khóa công khai dùng để xác thực chữ ký số từ thiết bị trong mỗi lần đăng nhập,. |
| user\_webauthn\_credentials | sign\_count | INT | NO | 0 | CHECK (sign\_count >= 0) | Bộ đếm số lần sử dụng nhằm chống lại các cuộc tấn công phát lại (Replay Attack),. |
| user\_webauthn\_credentials | transports | TEXT[] | YES | NULL |  | Mảng lưu các phương thức kết nối được hỗ trợ (VD: {'usb', 'nfc', 'ble', 'internal'}). |
| user\_webauthn\_credentials | last\_used\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm gần nhất thiết bị này được sử dụng để đăng nhập. |
| user\_webauthn\_credentials | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm đăng ký thiết bị vào hệ thống (UTC),. |
| user\_backup\_codes | YSQL | Collection |  |  |  | Mã khôi phục khi người dùng mất thiết bị MFA. |
| user\_backup\_codes | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" và tối ưu hóa việc phân tán dữ liệu,. |
| user\_backup\_codes | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến tài khoản người dùng gốc trong hệ thống định danh toàn cầu,. |
| user\_backup\_codes | code\_hash | TEXT | NO |  |  | Chuỗi băm của mã dự phòng (tương tự mật khẩu, tuyệt đối không lưu dạng rõ),. |
| user\_backup\_codes | is\_used | BOOLEAN | NO | FALSE |  | Trạng thái mã đã được sử dụng hay chưa. |
| user\_backup\_codes | used\_at | TIMESTAMPTZ | YES | NULL |  | Ghi lại thời điểm chính xác mã này được sử dụng để khôi phục tài khoản. |
| user\_backup\_codes | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo mã (luôn lưu theo giờ UTC),. |
| tenant\_sso\_configs | YSQL | Collection |  |  |  | Cấu hình đăng nhập doanh nghiệp (SAML/OIDC) để tích hợp với Azure AD, Okta. |
| tenant\_sso\_configs | tenant\_id | UUID | NO |  | PRIMARY KEY, REFERENCES tenants(\_id) ON DELETE CASCADE | Định danh Tenant. Mỗi tổ chức thường chỉ có một cấu hình SSO chính,. Sử dụng UUID v7 để tối ưu hiệu năng. |
| tenant\_sso\_configs | provider\_type | VARCHAR(20) | NO |  | CHECK (provider\_type IN ('AZURE\_AD', 'OKTA', 'GOOGLE', 'SAML', 'OIDC')) | Loại nhà cung cấp định danh (IdP),. |
| tenant\_sso\_configs | entry\_point\_url | TEXT | NO |  |  | URL đăng nhập của nhà cung cấp định danh bên ngoài,. |
| tenant\_sso\_configs | issuer\_id | TEXT | YES | NULL |  | Định danh thực thể (Entity ID/Issuer) của IdP. |
| tenant\_sso\_configs | cert\_public\_key | TEXT | YES | NULL |  | Chứng chỉ PEM dùng để xác thực chữ ký số từ IdP (SAML),. |
| tenant\_sso\_configs | client\_id | VARCHAR(255) | YES | NULL |  | Client ID dùng cho phương thức OIDC. |
| tenant\_sso\_configs | client\_secret\_enc | TEXT | YES | NULL |  | Client Secret đã mã hóa (chỉ dùng cho OIDC). |
| tenant\_sso\_configs | attribute\_mapping | JSONB | NO | {}' |  | Ánh xạ các trường dữ liệu (VD: map 'mail' của IdP sang 'email' của hệ thống),. |
| tenant\_sso\_configs | is\_enforced | BOOLEAN | NO | FALSE |  | Nếu TRUE, bắt buộc nhân viên phải đăng nhập qua SSO, cấm dùng mật khẩu thông thường,. |
| tenant\_sso\_configs | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo cấu hình (UTC),. |
| tenant\_sso\_configs | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| tenant\_sso\_configs | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để chống ghi đè dữ liệu đồng thời. |
| auth\_verification\_codes | YSQL | Collection |  |  |  | Mã OTP hoặc Magic Link ngắn hạn để xác thực email hoặc đổi mật khẩu. |
| auth\_verification\_codes | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding. |
| auth\_verification\_codes | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định mã thuộc tổ chức nào (SaaS Isolation). |
| auth\_verification\_codes | identifier | VARCHAR(255) | NO |  |  | Email hoặc số điện thoại nhận mã xác thực. |
| auth\_verification\_codes | type | VARCHAR(30) | NO |  | CHECK (type IN ('EMAIL\_VERIFICATION', 'PASSWORD\_RESET', 'LOGIN\_OTP', 'MAGIC\_LINK')) | Phân loại mục đích của mã xác thực. |
| auth\_verification\_codes | code\_hash | TEXT | NO |  |  | Chuỗi băm (Hash) của mã bí mật để đảm bảo an toàn, không lưu dạng rõ. |
| auth\_verification\_codes | expires\_at | TIMESTAMPTZ | NO |  |  | Thời điểm mã hết hạn (thường từ 5-15 phút). |
| auth\_verification\_codes | attempt\_count | INT | NO | 0 | CHECK (attempt\_count <= 5) | Bộ đếm số lần nhập sai để chống tấn công Brute-force. |
| auth\_verification\_codes | metadata | JSONB | YES | {}' |  | Lưu ngữ cảnh bổ sung như redirect\_url hoặc device\_info. |
| auth\_verification\_codes | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo mã (UTC). |
| personal\_access\_tokens | YSQL | Collection |  |  |  | Token dành cho lập trình viên hoặc scripts tích hợp hệ thống. |
| personal\_access\_tokens | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất. Sử dụng UUID v7 để tối ưu sắp xếp theo thời gian và tránh "hotspot" trong DB phân tán. |
| personal\_access\_tokens | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định token thuộc tổ chức nào để đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| personal\_access\_tokens | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Người dùng sở hữu và tạo ra token này. |
| personal\_access\_tokens | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên gợi nhớ của token (Ví dụ: "Script Sync Excel", "Jenkins CI/CD"). |
| personal\_access\_tokens | token\_prefix | VARCHAR(10) | NO |  |  | Chuỗi tiền tố (Ví dụ: pat\_live\_) để người dùng nhận diện token mà không cần lộ toàn bộ. |
| personal\_access\_tokens | token\_hash | TEXT | NO |  | UNIQUE | Bản băm của token (SHA-256). Tuyệt đối không lưu token gốc. |
| personal\_access\_tokens | scopes | TEXT[] | NO |  |  | Mảng các quyền hạn (Ví dụ: ['user:read', 'report:export']) giới hạn phạm vi truy cập. |
| personal\_access\_tokens | last\_used\_at | TIMESTAMPTZ | YES | NULL |  | Ghi lại thời điểm gần nhất token này được sử dụng để gọi API. |
| personal\_access\_tokens | expires\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm hết hạn. Nếu NULL nghĩa là token vĩnh viễn (khuyến nghị có hạn). |
| personal\_access\_tokens | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái kích hoạt. Cho phép người dùng vô hiệu hóa nhanh token mà không cần xóa. |
| personal\_access\_tokens | created\_at | TIMESTAMPTZ | NO | NOW() |  | Thời điểm tạo mã token (luôn lưu theo giờ UTC). |
| personal\_access\_tokens | version | BIGINT | NO | 1 | CHECK (version >= 1) | Sử dụng cho cơ chế Optimistic Locking để tránh ghi đè dữ liệu đồng thời. |
| auth\_logs | ClickHouse | Collection |  |  |  |  |
| auth\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| auth\_logs | tenant\_id | UUID | NO |  |  | Định danh tổ chức sở hữu log này (Dùng để lọc dữ liệu),. |
| auth\_logs | user\_id | Nullable(UUID) | YES | NULL |  | ID người dùng nếu đăng nhập thành công hoặc email tồn tại. |
| auth\_logs | impersonator\_id | Nullable(UUID) | YES | NULL |  | ID nhân viên Support nếu đang sử dụng tính năng "Impersonation",. |
| auth\_logs | email\_attempted | String | NO |  |  | Email người dùng đã nhập vào khi thử đăng nhập. |
| auth\_logs | ip\_address | IPv6 | NO |  |  | Địa chỉ IP truy cập (Lưu chuẩn IPv6 để bao quát cả IPv4). |
| auth\_logs | user\_agent | String | NO |  |  | Thông tin trình duyệt và hệ điều hành (User Agent). |
| auth\_logs | is\_success | Bool | NO |  |  | true nếu thành công, false nếu thất bại,. |
| auth\_logs | login\_method | Enum8(...) | NO | PASSWORD' | PASSWORD, GOOGLE, SSO, MAGIC\_LINK | Phương thức xác thực được sử dụng,. |
| auth\_logs | failure\_reason | Enum8(...) | NO | NONE' | NONE, WRONG\_PW, MFA\_FAIL, LOCKED | Lý do thất bại (nếu có) để phục vụ phân tích bảo mật. |
| auth\_logs | created\_at | DateTime64(3) | NO | now() | UTC | Thời điểm phát sinh sự kiện, chính xác đến mili giây,. |
| Nhóm Phân quyền (Authorization - IAM) |  | Package |  |  |  | Kiểm soát quyền truy cập từ mức tính năng đến mức dữ liệu |
| roles | YSQL | Collection |  |  |  | Định nghĩa các vai trò (VD: Admin, Editor) và danh sách mã quyền đi kèm. |
| roles | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7, giúp tối ưu hóa sắp xếp theo thời gian và sharding,. |
| roles | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định vai trò này thuộc tổ chức nào (Sharding Key),. |
| roles | name | VARCHAR(100) | NO |  | CHECK (LENGTH(name) > 0) | Tên vai trò (VD: Admin, Editor, HR Manager). |
| roles | description | TEXT | YES | NULL |  | Mô tả chi tiết về trách nhiệm của vai trò này. |
| roles | type | VARCHAR(20) | NO | 'CUSTOM' | CHECK (type IN ('SYSTEM', 'CUSTOM')) | SYSTEM: Vai trò mặc định không thể xóa. CUSTOM: Vai trò do khách hàng tự định nghĩa. |
| roles | permission\_codes | TEXT[] | NO | {}' |  | Mảng chứa các mã quyền (VD: {'user:view', 'invoice:create'}). Lưu mảng giúp truy vấn nhanh mà không cần join bảng trung gian. |
| roles | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo vai trò (UTC),. |
| roles | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| roles | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking: Ngăn chặn xung đột khi nhiều Admin cùng sửa cấu hình vai trò,. |
| permissions | YSQL | Collection |  |  |  | Danh mục các hành động kỹ thuật do lập trình viên định nghĩa cứng trong code. |
| permissions | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian,. |
| permissions | code | VARCHAR(100) | NO |  | UNIQUE, CHECK (LENGTH(code) > 0) | Mã quyền duy nhất dùng trong code (VD: invoice:create, user:view),. |
| permissions | name | VARCHAR(255) | NO | - | - | Tên hiển thị của quyền trên giao diện quản trị. |
| permissions | app\_code | VARCHAR(50) | NO | - | REFERENCES applications(code) | Liên kết với ứng dụng sở hữu quyền này (VD: HRM, CRM) [Conversation History]. |
| permissions | parent\_code | VARCHAR(100) | YES | NULL | REFERENCES permissions(code) | Mã của quyền cha để tạo cấu trúc cây phân cấp [Conversation History]. |
| permissions | path | TEXT | YES | NULL | - | Materialized Path (VD: /HRM/PAYROLL/). Giúp truy vấn cả nhánh quyền cực nhanh [65, 112, Conversation History]. |
| permissions | is\_group | BOOLEAN | NO | FALSE | - | TRUE nếu chỉ là thư mục phân nhóm, FALSE nếu là quyền thực thi [Conversation History]. |
| permissions | description | TEXT | YES | NULL |  | Mô tả chi tiết ý nghĩa và phạm vi tác động của quyền này. |
| permissions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo quyền trong hệ thống (UTC),. |
| permissions | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật thông tin quyền gần nhất. |
| user\_roles | YSQL | Collection |  |  |  | Gán vai trò cho thành viên, hỗ trợ phạm vi dữ liệu (scope\_values) như theo phòng ban hoặc khu vực. |
| user\_roles | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sắp xếp theo thời gian và tránh "hotspot" khi ghi phân tán. |
| user\_roles | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation), xác định quan hệ này thuộc về khách hàng nào. |
| user\_roles | member\_id | UUID | NO |  | REFERENCES tenant\_members(\_id) ON DELETE CASCADE | Liên kết với hồ sơ nhân viên trong tổ chức (thay vì User gốc) để quản lý vòng đời nhân sự. |
| user\_roles | role\_id | UUID | NO |  | REFERENCES roles(\_id) ON DELETE CASCADE | Vai trò được gán (VD: Manager, Editor). |
| user\_roles | scope\_type | VARCHAR(50) | NO | 'GLOBAL' | CHECK (scope\_type IN ('GLOBAL', 'DEPARTMENT', 'LOCATION', 'PROJECT')) | Phạm vi áp dụng quyền: Toàn cục, theo phòng ban, hoặc theo dự án cụ thể. |
| user\_roles | scope\_values | TEXT[] | NO | '{}' |  | Mảng chứa các UUID của phòng ban/vị trí tương ứng với scope\_type. |
| user\_roles | assigned\_by | UUID | YES | NULL |  | ID của người thực hiện gán quyền để phục vụ truy vết (Audit). |
| user\_roles | assigned\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm chính xác quyền được gán (UTC). |
| relationship\_tuples | YSQL | Collection |  |  |  | Mô hình phân quyền dựa trên quan hệ (ReBAC - Google Zanzibar) cho các kịch bản chia sẻ tài nguyên phức tạp. |
| relationship\_tuples | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Định danh tổ chức sở hữu quan hệ này (SaaS Isolation). |
| relationship\_tuples | namespace | VARCHAR(50) | NO |  | CHECK (LENGTH(namespace) > 0) | Loại tài nguyên (Object Namespace) như: document, folder, project. |
| relationship\_tuples | object\_id | UUID | NO |  |  | Định danh cụ thể của tài nguyên (Sử dụng UUID v7 để tối ưu). |
| relationship\_tuples | relation | VARCHAR(50) | NO |  |  | Mối quan hệ như: viewer, editor, owner, parent. |
| relationship\_tuples | subject\_namespace | VARCHAR(50) | NO |  |  | Loại đối tượng được gán quyền: user, group, hoặc một folder (nếu thừa kế). |
| relationship\_tuples | subject\_id | UUID | NO |  |  | Định danh của đối tượng (User/Group ID). |
| relationship\_tuples | subject\_relation | VARCHAR(50) | YES | NULL |  | Dùng cho quan hệ lồng nhau (VD: "Thành viên của nhóm A"). |
| relationship\_tuples | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo quan hệ (UTC). |
| access\_control\_lists | YSQL | Collection |  |  |  | Kiểm soát truy cập chi tiết cho từng tài nguyên cụ thể (VD: Folder, Document). |
| access\_control\_lists | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding. |
| access\_control\_lists | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| access\_control\_lists | resource\_type | VARCHAR(50) | NO |  | CHECK (LENGTH(resource\_type) > 0) | Loại tài nguyên (VD: 'DASHBOARD', 'REPORT', 'FOLDER'). |
| access\_control\_lists | resource\_id | UUID | NO |  |  | ID cụ thể của tài nguyên được phân quyền. |
| access\_control\_lists | subject\_type | VARCHAR(20) | NO |  | CHECK (subject\_type IN ('MEMBER', 'GROUP', 'ROLE')) | Loại đối tượng nhận quyền (Thành viên, Nhóm, hoặc Vai trò). |
| access\_control\_lists | subject\_id | UUID | NO |  |  | ID của đối tượng nhận quyền (Member ID hoặc Group ID). |
| access\_control\_lists | action | VARCHAR(50) | NO |  | CHECK (action IN ('READ', 'WRITE', 'DELETE', 'SHARE')) | Hành động được phép thực hiện trên tài nguyên. |
| access\_control\_lists | is\_allowed | BOOLEAN | NO | TRUE |  | TRUE là cho phép, FALSE là chặn cụ thể (Deny). |
| access\_control\_lists | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC) phục vụ truy vết. |
| Nhóm Quản trị và Tuân thủ (Governance & Compliance) |  | Package |  |  |  | Đáp ứng các yêu cầu của khách hàng Enterprise lớn |
| tenant\_domains | YSQL | Collection |  |  |  | Xác thực tên miền sở hữu (VD: @fpt.com) để tự động quản lý thành viên và thực thi SSO. |
| tenant\_domains | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" khi chèn dữ liệu phân tán. |
| tenant\_domains | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết đến tổ chức sở hữu tên miền này. |
| tenant\_domains | domain | VARCHAR(255) | NO |  | UNIQUE, CHECK (domain \~ '^[a-z0-9.-]+$') | Tên miền (VD: fpt.com). Phải là duy nhất trên toàn hệ thống để xác định chủ quyền. |
| tenant\_domains | verification\_status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'VERIFIED')) | Trạng thái xác minh chủ sở hữu tên miền. |
| tenant\_domains | verification\_method | VARCHAR(20) | YES | NULL | CHECK (method IN ('DNS\_TXT', 'HTML\_FILE')) | Phương thức khách hàng chọn để chứng minh quyền sở hữu (DNS hoặc file HTML). |
| tenant\_domains | verification\_token | VARCHAR(100) | YES | NULL |  | Mã bí mật khách hàng phải cấu hình vào DNS/Web server để hệ thống đối soát. |
| tenant\_domains | policy | VARCHAR(20) | NO | NONE' | CHECK (policy IN ('NONE', 'CAPTURE', 'ENFORCE\_SSO')) | CAPTURE: Tự động đưa user đăng ký bằng email đuôi này vào Tenant. ENFORCE\_SSO: Bắt buộc đăng nhập qua SSO. |
| tenant\_domains | verified\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm xác thực thành công (UTC). |
| tenant\_domains | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm bản ghi được tạo (UTC). |
| tenant\_invitations | YSQL | Collection |  |  |  | Quản lý quy trình mời và gia nhập của người dùng mới. |
| tenant\_invitations | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp thời gian,. |
| tenant\_invitations | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định lời mời thuộc về tổ chức nào (SaaS Isolation),. |
| tenant\_invitations | email | VARCHAR(255) | NO |  | CHECK (email \~\* '^[A-Z0-9.\_%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$') | Email của người nhận lời mời,. |
| tenant\_invitations | role\_ids | TEXT[] | YES | {}' |  | Mảng chứa các mã vai trò (Roles) dự kiến gán cho người dùng sau khi chấp nhận,. |
| tenant\_invitations | department\_id | UUID | YES | NULL |  | Phòng ban dự kiến người mới sẽ tham gia,. |
| tenant\_invitations | token | VARCHAR(100) | NO |  | UNIQUE | Mã bí mật duy nhất đính kèm trong link mời gửi qua email,. |
| tenant\_invitations | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')) | Trạng thái của lời mời (Chờ, Đã nhận, Hết hạn hoặc Bị thu hồi),. |
| tenant\_invitations | expires\_at | TIMESTAMPTZ | NO |  | CHECK (expires\_at > created\_at) | Thời điểm link hết hạn (UTC),. |
| tenant\_invitations | invited\_by | UUID | YES | NULL |  | ID của người gửi lời mời để phục vụ truy vết (Audit),. |
| tenant\_invitations | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo lời mời (UTC). |
| access\_reviews | YSQL | Collection |  |  |  | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| access\_reviews | \_id | UUID | NO |  | PRIMARY KEY | Định danh đợt rà soát. Sử dụng UUID v7 (sinh từ tầng App) để tối ưu hóa sắp xếp và sharding,,. |
| access\_reviews | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation). Mỗi Tenant quản lý các đợt rà soát riêng,. |
| access\_reviews | name | VARCHAR(255) | NO |  | CHECK (LENGTH(name) > 0) | Tên đợt rà soát (VD: "Rà soát quyền hạn Q4/2024"). |
| access\_reviews | description | TEXT | YES | NULL |  | Mô tả chi tiết mục tiêu hoặc phạm vi của đợt rà soát này. |
| access\_reviews | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'IN\_PROGRESS', 'COMPLETED', 'CANCELLED')) | Trạng thái của đợt rà soát. |
| access\_reviews | deadline | TIMESTAMPTZ | NO |  |  | Thời hạn cuối cùng phải hoàn thành việc rà soát. |
| access\_reviews | created\_by | UUID | NO |  | REFERENCES users(\_id) | Người khởi tạo đợt rà soát (thường là Security Admin). |
| access\_reviews | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo đợt rà soát (UTC),. |
| access\_reviews | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật trạng thái gần nhất. |
| access\_reviews | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để tránh xung đột khi nhiều Admin cùng điều chỉnh cấu hình. |
| access\_review\_items | YSQL | Collection |  |  |  | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| access\_review\_items | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7,. |
| access\_review\_items | review\_id | UUID | NO |  | REFERENCES access\_reviews(\_id) ON DELETE CASCADE | Liên kết với đợt rà soát tổng thể. |
| access\_review\_items | reviewer\_id | UUID | NO |  | REFERENCES tenant\_members(\_id) | Người chịu trách nhiệm rà soát (thường là Manager trực tiếp). |
| access\_review\_items | target\_member\_id | UUID | NO |  | REFERENCES tenant\_members(\_id) | Nhân viên đang được kiểm tra quyền hạn. |
| access\_review\_items | role\_id | UUID | NO |  | REFERENCES roles(\_id) | Vai trò cụ thể đang được xem xét để giữ lại hoặc thu hồi. |
| access\_review\_items | decision | VARCHAR(20) | NO | PENDING' | CHECK (decision IN ('PENDING', 'KEEP', 'REVOKE')) | Quyết định: Đang chờ, Giữ lại, hoặc Thu hồi quyền. |
| access\_review\_items | reason | TEXT | YES | NULL |  | Lý do cho quyết định (bắt buộc nếu chọn REVOKE). |
| access\_review\_items | reviewed\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm người rà soát thực hiện xác nhận,. |
| access\_review\_items | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm mục rà soát được tạo (UTC). |
| access\_review\_items | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật trạng thái mục rà soát. |
| scim\_directories | YSQL | Collection |  |  |  | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| scim\_directories | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, giúp sắp xếp dữ liệu theo thời gian thực,. |
| scim\_directories | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | ID của tổ chức sở hữu kết nối thư mục này (SaaS Isolation),. |
| scim\_directories | provider\_type | VARCHAR(20) | NO |  | CHECK (provider\_type IN ('AZURE\_AD', 'OKTA', 'ONELOGIN', 'CUSTOM')) | Loại nhà cung cấp định danh (IdP) như Azure AD, Okta.... |
| scim\_directories | scim\_token\_hash | TEXT | NO |  | UNIQUE | Bản băm của Bearer Token dùng để xác thực các request SCIM từ IdP gửi đến. |
| scim\_directories | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái kích hoạt của kết nối. |
| scim\_directories | last\_synced\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm cuối cùng IdP thực hiện đồng bộ dữ liệu. |
| scim\_directories | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo cấu hình kết nối (UTC),. |
| scim\_directories | version | BIGINT | NO | 1 | CHECK (version >= 1) | Sử dụng cho cơ chế Optimistic Locking khi cập nhật cấu hình. |
| scim\_mappings | YSQL | Collection |  |  |  | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| scim\_mappings | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7,. |
| scim\_mappings | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | ID của tổ chức sở hữu ánh xạ này để đảm bảo cô lập dữ liệu (SaaS Isolation),. |
| scim\_mappings | directory\_id | UUID | NO |  | REFERENCES scim\_directories(\_id) ON DELETE CASCADE | Liên kết với cấu hình kết nối thư mục SCIM cụ thể. |
| scim\_mappings | external\_id | VARCHAR(255) | NO |  |  | ID của đối tượng (User/Group) được cung cấp bởi hệ thống IdP bên ngoài (Azure AD/Okta). |
| scim\_mappings | internal\_entity\_type | VARCHAR(20) | NO |  | CHECK (internal\_entity\_type IN ('USER', 'GROUP')) | Phân loại đối tượng ánh xạ là Người dùng hoặc Nhóm. |
| scim\_mappings | internal\_entity\_id | UUID | NO |  |  | ID của đối tượng tương ứng trong hệ thống nội bộ (trỏ đến users hoặc user\_groups). |
| scim\_mappings | data\_hash | VARCHAR(64) | YES | NULL |  | Mã băm (Checksum) để so sánh và phát hiện thay đổi dữ liệu từ lần đồng bộ trước. |
| scim\_mappings | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật ánh xạ lần cuối (UTC),. |
| legal\_documents | YSQL | Collection |  |  |  | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| legal\_documents | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian thực. |
| legal\_documents | type | VARCHAR(50) | NO |  | CHECK (type IN ('TERMS\_OF\_SERVICE', 'PRIVACY\_POLICY', 'COOKIE\_POLICY', 'EULA')) | Phân loại loại văn bản pháp lý. |
| legal\_documents | version | VARCHAR(20) | NO |  |  | Phiên bản của văn bản (VD: 'v1.0', '2024-JAN'). |
| legal\_documents | title | TEXT | NO |  | CHECK (LENGTH(title) > 0) | Tiêu đề hiển thị của văn bản. |
| legal\_documents | content\_url | TEXT | NO |  | CHECK (content\_url \~\* '^https?://') | Đường dẫn đến nội dung văn bản trên Object Storage. Dùng TEXT thay vì VARCHAR(255) để tránh rủi ro URL dài. |
| legal\_documents | is\_active | BOOLEAN | NO | FALSE |  | Đánh dấu phiên bản hiện hành. Chỉ một phiên bản trên mỗi loại được là TRUE. |
| legal\_documents | published\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm công bố văn bản chính thức (UTC). |
| legal\_documents | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi trong hệ thống. |
| legal\_documents | version\_locking | BIGINT | NO | 1 |  | Cơ chế Optimistic Locking để tránh xung đột khi cập nhật. |
| user\_consents | YSQL | Collection |  |  |  | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| user\_consents | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian thực,. |
| user\_consents | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | ID của người dùng thực hiện đồng ý. |
| user\_consents | document\_id | UUID | NO |  | REFERENCES legal\_documents(\_id) | Liên kết đến phiên bản văn bản pháp lý cụ thể. |
| user\_consents | agreed\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm chính xác người dùng bấm nút đồng ý (UTC),. |
| user\_consents | ip\_address | INET | NO |  |  | Địa chỉ IP của người dùng tại thời điểm đồng ý (Phục vụ truy vết/Audit),. |
| user\_consents | user\_agent | TEXT | YES | NULL |  | Thông tin trình duyệt/thiết bị của người dùng để tăng tính pháp lý,. |
| user\_consents | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để quản lý phiên bản dòng dữ liệu,. |
| security\_audit\_logs | ClickHouse | Collection |  |  |  | (Nhật ký an ninh lõi): Tập trung vào các sự kiện an ninh cấp độ hệ thống như: đăng nhập thất bại, gán vai trò (role) cho người dùng, tạo API Key, hoặc thay đổi chính sách bảo mật |
| security\_audit\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian,. |
| security\_audit\_logs | tenant\_id | UUID | NO |  |  | Định danh tổ chức sở hữu hành động này để phân vùng dữ liệu,. |
| security\_audit\_logs | actor\_id | UUID | NO |  |  | ID của người dùng thực hiện hành động. |
| security\_audit\_logs | impersonator\_id | Nullable(UUID) | YES | NULL |  | ID nhân viên hỗ trợ nếu đang sử dụng tính năng "Impersonation" (giả danh),. |
| security\_audit\_logs | event\_category | Enum8(...) | NO |  | IAM, AUTH, BILLING, DATA | Nhóm sự kiện chính để lọc nhanh (Ví dụ: Bảo mật, Thanh toán),. |
| security\_audit\_logs | event\_action | String | NO |  |  | Hành động cụ thể (Ví dụ: ROLE\_ASSIGNED, API\_KEY\_CREATED). |
| security\_audit\_logs | target\_id | Nullable(UUID) | YES | NULL |  | ID của đối tượng bị tác động (Ví dụ: ID của User bị khóa). |
| security\_audit\_logs | resource\_type | String | NO |  |  | Loại tài nguyên bị tác động (Ví dụ: USER, INVOICE, ROLE). |
| security\_audit\_logs | ip\_address | IPv6 | NO |  |  | Địa chỉ IP của người thực hiện (Lưu IPv6 để bao quát cả IPv4). |
| security\_audit\_logs | user\_agent | String | NO |  |  | Thông tin trình duyệt và hệ điều hành. |
| security\_audit\_logs | details | String | NO | {}' |  | Lưu chi tiết thay đổi dưới dạng JSON String (Dùng JSONExtract khi truy vấn),. |
| security\_audit\_logs | created\_at | DateTime64(3) | NO | now() | UTC | Thời điểm xảy ra sự kiện, chính xác đến mili giây,. |
| user\_delegations | YSQL | Collection |  |  |  | Cho phép ủy quyền hành động (Impersonation) có thời hạn và có kiểm soát. |
| user\_delegations | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, giúp sắp xếp theo thời gian và tối ưu sharding. |
| user\_delegations | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu giữa các tổ chức (SaaS Isolation). |
| user\_delegations | delegator\_id | UUID | NO |  | REFERENCES users(\_id) | ID của người ủy quyền (người cho đi quyền hạn - ví dụ: Giám đốc). |
| user\_delegations | delegatee\_id | UUID | NO |  | REFERENCES users(\_id) | ID của người được ủy quyền (người nhận quyền - ví dụ: Thư ký). |
| user\_delegations | scopes | TEXT[] | NO | {}' |  | Mảng danh sách các quyền được phép thực hiện (VD: ['calendar:read', 'email:send']). |
| user\_delegations | starts\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm việc ủy quyền bắt đầu có hiệu lực. |
| user\_delegations | expires\_at | TIMESTAMPTZ | NO |  | CHECK (expires\_at > starts\_at) | Thời điểm hết hạn ủy quyền (bắt buộc phải có hạn để đảm bảo an ninh). |
| user\_delegations | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái kích hoạt, cho phép thu hồi quyền nhanh chóng bằng tay. |
| user\_delegations | reason | TEXT | YES | NULL |  | Lý do ủy quyền (phục vụ mục đích tra soát/audit). |
| user\_delegations | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm bản ghi được tạo (UTC). |
| Nhóm Quản lý Truy cập (Access Management) |  | Package |  |  |  |  |
| api\_keys | YSQL | Collection |  |  |  |  |
| api\_keys | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian thực. |
| api\_keys | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết đến tổ chức (Tenant) sở hữu API Key này. |
| api\_keys | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên gợi nhớ cho Key (Ví dụ: "Tích hợp ERP", "Sync dữ liệu"). |
| api\_keys | key\_prefix | VARCHAR(10) | NO |  |  | 10 ký tự đầu của Key để hiển thị trên giao diện quản trị (VD: sk\_live\_...). |
| api\_keys | key\_hash | TEXT | NO |  | UNIQUE | Tuyệt đối không lưu Key gốc. Chỉ lưu bản băm (Hash) để đối soát khi xác thực. |
| api\_keys | scopes | TEXT[] | NO | {}' |  | Mảng danh sách các quyền hạn được cấp (VD: ['crm:read', 'hrm:write']). |
| api\_keys | allowed\_ips | CIDR[] | YES | NULL |  | Giới hạn các dải IP được phép truy cập (IP Whitelist) để tăng cường bảo mật. |
| api\_keys | expires\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm Key hết hạn. Nếu NULL là vô hạn (không khuyến nghị cho Enterprise). |
| api\_keys | last\_used\_at | TIMESTAMPTZ | YES | NULL |  | Ghi lại thời điểm cuối cùng Key này được sử dụng để truy cập hệ thống. |
| api\_keys | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo Key. |
| api\_keys | created\_by | UUID | YES | NULL | REFERENCES users(\_id) | ID của người dùng thực hiện tạo Key này. |
| api\_keys | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để quản lý phiên bản dòng dữ liệu. |
| service\_accounts | YSQL | Collection |  |  |  |  |
| service\_accounts | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding. |
| service\_accounts | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định tài khoản này thuộc về tổ chức nào,. |
| service\_accounts | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên hiển thị (VD: "GitHub Action Bot", "ERP Sync"). |
| service\_accounts | description | TEXT | YES | NULL |  | Mô tả chi tiết mục đích sử dụng của tài khoản. |
| service\_accounts | client\_id | VARCHAR(64) | NO |  | UNIQUE | Mã định danh duy nhất dùng để xác thực thay cho email. |
| service\_accounts | client\_secret\_hash | TEXT | NO |  |  | Bản băm mật khẩu của tài khoản máy. |
| service\_accounts | member\_id | UUID | NO |  | REFERENCES tenant\_members(\_id) | Liên kết sang bảng thành viên để gán quyền RBAC như người thật. |
| service\_accounts | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái kích hoạt của tài khoản. |
| service\_accounts | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo tài khoản (UTC). |
| service\_accounts | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| service\_accounts | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| user\_devices | YSQL | Collection |  |  |  |  |
| user\_devices | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian thực. |
| user\_devices | user\_id | UUID | NO |  | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết với tài khoản người dùng chủ sở hữu thiết bị. |
| user\_devices | device\_fingerprint | VARCHAR(255) | NO |  | UNIQUE | Mã định danh thiết bị (được tạo từ trình duyệt, OS và phần cứng). |
| user\_devices | name | TEXT | YES | NULL |  | Tên gợi nhớ do người dùng đặt (VD: "Macbook Pro của An"). |
| user\_devices | user\_agent\_parsed | JSONB | NO | {}' |  | Chứa thông tin chi tiết đã phân tách từ User Agent (OS, phiên bản trình duyệt). |
| user\_devices | trust\_status | VARCHAR(20) | NO | UNTRUSTED' | CHECK (trust\_status IN ('UNTRUSTED', 'TRUSTED', 'BLOCKED')) | Trạng thái tin cậy của thiết bị để quyết định có cần yêu cầu MFA hay không. |
| user\_devices | last\_ip | INET | YES | NULL |  | Địa chỉ IP cuối cùng thiết bị này sử dụng để truy cập. |
| user\_devices | last\_active\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cuối cùng thiết bị hoạt động trên hệ thống. |
| user\_devices | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm thiết bị lần đầu được ghi nhận. |
| tenant\_app\_routes | YSQL | Collection |  |  |  |  |
| tenant\_app\_routes | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| tenant\_app\_routes | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết với Tenant sở hữu route này. |
| tenant\_app\_routes | app\_code | VARCHAR(50) | NO |  | CHECK (LENGTH(app\_code) > 0) | Mã ứng dụng đích (VD: HRM, CRM, DASHBOARD). |
| tenant\_app\_routes | domain | VARCHAR(255) | NO |  | CHECK (domain \~ '^[a-z0-9.-]+$') | Tên miền truy cập (VD: hrm.fpt.com). Chỉ chứa chữ thường, số, dấu chấm và gạch ngang. |
| tenant\_app\_routes | path\_prefix | VARCHAR(100) | NO | /' | CHECK (path\_prefix \~ '^/[a-z0-9-/]\*$') | Đường dẫn tiền tố (VD: /hrm). Phải bắt đầu bằng dấu /. |
| tenant\_app\_routes | is\_primary | BOOLEAN | NO | FALSE |  | TRUE nếu là Domain chính để hệ thống sinh link (Canonical URL). |
| tenant\_app\_routes | is\_custom\_domain | BOOLEAN | NO | FALSE |  | TRUE nếu là tên miền riêng của khách, FALSE nếu là subdomain hệ thống. |
| tenant\_app\_routes | ssl\_status | VARCHAR(20) | NO | NONE' | CHECK (ssl\_status IN ('NONE', 'PENDING', 'ACTIVE', 'FAILED')) | Trạng thái chứng chỉ HTTPS cho custom domain. |
| tenant\_app\_routes | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo cấu hình định tuyến (UTC). |
| tenant\_app\_routes | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_app\_routes | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để chống ghi đè đồng thời. |
| tenant\_rate\_limits | YSQL | Collection |  |  |  |  |
| tenant\_rate\_limits | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| tenant\_rate\_limits | tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | Liên kết tới Tenant. Nếu NULL nghĩa là áp dụng cho Global hoặc Package. |
| tenant\_rate\_limits | package\_id | UUID | YES | NULL | REFERENCES packages(\_id) | Liên kết tới gói cước. Dùng để áp giới hạn theo gói (VD: Gói Free giới hạn thấp hơn). |
| tenant\_rate\_limits | api\_group | VARCHAR(50) | NO |  | CHECK (LENGTH(api\_group) > 0) | Nhóm API cần giới hạn (VD: REPORTING\_API, AUTH\_API, CORE\_API). |
| tenant\_rate\_limits | limit\_count | INT | NO |  | CHECK (limit\_count > 0) | Số lượng request tối đa được phép. |
| tenant\_rate\_limits | window\_seconds | INT | NO | 60 | CHECK (window\_seconds > 0) | Khoảng thời gian (giây) áp dụng giới hạn. |
| tenant\_rate\_limits | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái hiệu lực của cấu hình. |
| tenant\_rate\_limits | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo (UTC). |
| tenant\_rate\_limits | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_rate\_limits | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| oauth\_clients | YSQL | Collection |  |  |  |  |
| oauth\_clients | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 để tối ưu hóa việc sắp xếp theo thời gian và sharding. |
| oauth\_clients | tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định ứng dụng này thuộc về tổ chức nào (nếu là ứng dụng nội bộ). |
| oauth\_clients | client\_id | VARCHAR(64) | NO |  | UNIQUE | Mã định danh công khai của ứng dụng dùng để nhận diện khi đăng nhập. |
| oauth\_clients | client\_secret\_hash | TEXT | NO |  |  | Bản băm bảo mật của mã bí mật (Secret Key). Tuyệt đối không lưu plain-text. |
| oauth\_clients | name | TEXT | NO |  | CHECK (length(name) > 0) | Tên hiển thị của ứng dụng khách (Ví dụ: "Mobile App", "Portal"). |
| oauth\_clients | logo\_url | TEXT | YES | NULL |  | URL ảnh đại diện của ứng dụng hiển thị trên màn hình xin quyền. |
| oauth\_clients | redirect\_uris | TEXT[] | NO |  |  | Mảng các URL được phép quay lại sau khi xác thực thành công để chống tấn công chuyển hướng. |
| oauth\_clients | allowed\_scopes | TEXT[] | YES | NULL |  | Danh sách các quyền (scopes) mà ứng dụng này được phép yêu cầu (Ví dụ: openid, profile). |
| oauth\_clients | is\_trusted | BOOLEAN | NO | FALSE |  | Nếu TRUE, hệ thống sẽ tự động phê duyệt mà không hiển thị màn hình hỏi ý kiến người dùng (Consent). |
| oauth\_clients | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi chuẩn UTC. |
| oauth\_clients | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cấu hình gần nhất. |
| webhooks | YSQL | Collection |  |  |  |  |
| webhooks | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| webhooks | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Thuộc sở hữu của Tenant nào. |
| webhooks | target\_url | TEXT | NO |  | CHECK (target\_url \~\* '^https?://') | URL đích nhận thông báo. Dùng TEXT để tránh giới hạn độ dài. |
| webhooks | secret\_key | TEXT | NO |  |  | Dùng để ký (sign) payload, giúp bên nhận xác thực dữ liệu từ hệ thống. |
| webhooks | subscribed\_events | TEXT[] | NO |  |  | Mảng danh sách các sự kiện đăng ký (VD: ['user.created', 'invoice.paid']). |
| webhooks | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái hoạt động của Webhook. |
| webhooks | failure\_count | INT | NO | 0 | CHECK (failure\_count >= 0) | Số lần gửi lỗi liên tiếp. Nếu quá 10 lần, hệ thống tự động tắt (is\_active = FALSE). |
| webhooks | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo (UTC). |
| webhooks | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| webhooks | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| api\_usage\_logs | ClickHouse | Collection |  |  |  |  |
| api\_usage\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| api\_usage\_logs | tenant\_id | UUID | NO |  |  | Định danh khách hàng sở hữu log. |
| api\_usage\_logs | app\_code | String | NO |  | CHECK (length(app\_code) > 0) | Mã ứng dụng (VD: HRM, CRM, POS),. |
| api\_usage\_logs | api\_endpoint | String | NO |  |  | Đường dẫn API đã gọi. |
| api\_usage\_logs | api\_method | Enum8(...) | NO |  | GET' = 1, 'POST' = 2, 'PUT' = 3, 'DELETE' = 4, 'PATCH' = 5, 'OPTIONS' = 6 | Phương thức HTTP (Dùng Enum để nén dữ liệu),. |
| api\_usage\_logs | status\_code | Int16 | NO |  |  | Mã phản hồi HTTP (VD: 200, 401, 500). |
| api\_usage\_logs | request\_size | Int64 | NO | 0 | CHECK (request\_size >= 0) | Dung lượng request (bytes) để tính bandwidth. |
| api\_usage\_logs | response\_size | Int64 | NO | 0 | CHECK (response\_size >= 0) | Dung lượng response (bytes) để tính bandwidth. |
| api\_usage\_logs | latency\_ms | Int32 | NO |  |  | Thời gian xử lý của API (mili giây). |
| api\_usage\_logs | api\_key\_id | Nullable(UUID) | YES | NULL |  | ID của API Key nếu dùng Machine-to-Machine,. |
| api\_usage\_logs | created\_at | DateTime64(3) | NO | now() | UTC | Thời điểm ghi log, độ chính xác mili-giây,. |
| webhook\_delivery\_logs | ClickHouse | Collection |  |  |  |  |
| webhook\_delivery\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| webhook\_delivery\_logs | tenant\_id | UUID | NO |  |  | ID tổ chức sở hữu webhook (Dùng để phân vùng truy vấn). |
| webhook\_delivery\_logs | webhook\_id | UUID | NO |  |  | Tham chiếu đến cấu hình webhook gốc tại YugabyteDB. |
| webhook\_delivery\_logs | event\_type | String | NO |  |  | Loại sự kiện (Ví dụ: user.created, invoice.paid). |
| webhook\_delivery\_logs | target\_url | String | NO |  | CHECK (target\_url \~\* '^https?://') | URL đích nhận dữ liệu. |
| webhook\_delivery\_logs | payload | String | NO |  |  | Nội dung dữ liệu (JSON) đã gửi đi. |
| webhook\_delivery\_logs | response\_body | String | YES | NULL |  | Nội dung phản hồi từ hệ thống của khách hàng. |
| webhook\_delivery\_logs | status\_code | Int16 | NO |  |  | Mã trạng thái HTTP trả về (Ví dụ: 200, 404, 500). |
| webhook\_delivery\_logs | is\_success | Bool | NO |  |  | Trạng thái gửi thành công hay thất bại. |
| webhook\_delivery\_logs | latency\_ms | Int32 | NO |  |  | Thời gian xử lý của phía khách hàng (mili giây). |
| webhook\_delivery\_logs | attempt\_number | Int8 | NO | 1 |  | Số lần thử lại (Retry) cho sự kiện này. |
| webhook\_delivery\_logs | created\_at | DateTime64(3) | NO | now() | UTC | Thời điểm thực hiện gửi tin (Chính xác đến ms). |
| traffic\_logs | ClickHouse | Collection |  |  |  | Bảng này ghi nhận mọi yêu cầu (Request) đi vào hệ thống, bao gồm các thông số về băng thông, độ trễ và ngữ cảnh khách hàng |
| traffic\_logs | \_id | UUID | NO | - | Khóa chính logic (UUID v7) | Định danh duy nhất cho mỗi bản ghi log. |
| traffic\_logs | tenant\_id | UUID | NO | - | Thành phần Sorting Key | Định danh tổ chức sở hữu lưu lượng để cô lập dữ liệu khách hàng. |
| traffic\_logs | user\_id | Nullable(UUID) | YES | NULL | - | ID người dùng thực hiện request (nếu đã xác thực). |
| traffic\_logs | app\_code | String | NO | - | Thành phần Sorting Key | Mã ứng dụng nhận request (VD: HRM, CRM, POS). |
| traffic\_logs | method | Enum8(...) | NO | - | GET=1, POST=2, ... | Phương thức HTTP, dùng Enum để tối ưu nén. |
| traffic\_logs | domain | String | NO | - | - | Tên miền yêu cầu (VD: hr.abc.com). |
| traffic\_logs | path | String | NO | - | - | Đường dẫn cụ thể (VD: /api/v1/employees). |
| traffic\_logs | status\_code | Int16 | NO | - | - | Mã trạng thái HTTP (VD: 200, 404, 500). |
| traffic\_logs | latency\_ms | Int32 | NO | - | - | Độ trễ xử lý của hệ thống tính bằng mili-giây. |
| traffic\_logs | request\_size | Int64 | NO | 0 | Byte | Dung lượng request đầu vào để tính Bandwidth. |
| traffic\_logs | response\_size | Int64 | NO | 0 | Byte | Dung lượng response đầu ra để tính Bandwidth. |
| traffic\_logs | ip\_address | IPv6 | NO | - | - | Địa chỉ IP người dùng (Hỗ trợ cả IPv4 và IPv6). |
| traffic\_logs | user\_agent | String | YES | NULL | - | Thông tin thiết bị và trình duyệt truy cập. |
| traffic\_logs | data\_region | String | NO | DEFAULT' | - | Vùng vật lý phát sinh traffic phục vụ tuân thủ dữ liệu. |
| traffic\_logs | timestamp | DateTime64(3) | NO | now() | UTC | Thời điểm chính xác request xảy ra (độ chính xác ms). |
| audit\_logs | ClickHouse | Collection |  |  |  | Nhật ký kiểm tra hệ thống. Lưu vết toàn bộ các hành động thay đổi dữ liệu của người dùng trên hệ thống. Đặc biệt, bảng này trong mô hình Enterprise sẽ bao gồm trường impersonator\_id để ghi lại định danh của nhân viên hỗ trợ nếu họ đang sử dụng tính năng "Impersonation" (giả danh khách hàng) để xử lý sự cố |
| audit\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| audit\_logs | tenant\_id | UUID | NO |  |  | Định danh khách hàng (Dùng để lọc dữ liệu theo Tenant),. |
| audit\_logs | user\_id | UUID | NO |  |  | ID của người dùng thực hiện hành động. |
| audit\_logs | impersonator\_id | UUID | YES | NULL |  | ID nhân viên Support nếu đang sử dụng tính năng "Impersonation",. |
| audit\_logs | event\_time | DateTime64(3) | NO | now() | UTC | Thời điểm xảy ra sự kiện, chính xác đến mili giây,. |
| audit\_logs | action | String | NO |  | CHECK (length(action) > 0) | Loại hành động (VD: UPDATE\_SALARY, DELETE\_USER),. |
| audit\_logs | resource | String | NO |  |  | Tên thực thể bị tác động (VD: employees, invoices),. |
| audit\_logs | resource\_id | String | YES | NULL |  | ID của bản ghi cụ thể bị tác động. |
| audit\_logs | details | String | YES | NULL |  | Lưu snapshot thay đổi (thường là JSON lưu Diff cũ/mới),. |
| audit\_logs | ip\_address | String | NO |  |  | Địa chỉ IP của người thực hiện. |
| audit\_logs | user\_agent | String | YES | NULL |  | Thông tin trình duyệt và thiết bị. |
| audit\_logs | status | Enum8(...) | NO | SUCCESS' | SUCCESS'=1, 'FAILED'=2 | Trạng thái thực hiện hành động,. |
| outbox\_events | YSQL | Collection |  |  |  |  |
| outbox\_events | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sharding và sắp xếp thời gian,. |
| outbox\_events | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) | Xác định sự kiện thuộc về khách hàng nào để hỗ trợ lọc và phân mảnh dữ liệu,. |
| outbox\_events | aggregate\_type | VARCHAR(50) | NO |  | CHECK (length(aggregate\_type) > 0) | Loại thực thể phát sinh sự kiện (VD: TENANT, USER, ORDER). |
| outbox\_events | aggregate\_id | UUID | NO |  |  | ID của bản ghi nghiệp vụ cụ thể vừa thay đổi. |
| outbox\_events | event\_type | VARCHAR(50) | NO |  |  | Tên hành động cụ thể (VD: TENANT\_CREATED, PLAN\_UPGRADED). |
| outbox\_events | payload | JSONB | NO | {}' |  | Dữ liệu snapshot của thực thể tại thời điểm phát sinh sự kiện để các service khác xử lý,. |
| outbox\_events | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')) | Trạng thái xử lý của sự kiện bởi Event Worker. |
| outbox\_events | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm sự kiện được tạo ra (chuẩn UTC),. |
| outbox\_events | published\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm sự kiện đã được đẩy thành công sang Kafka. |
| user\_registration\_logs | ClickHouse | Collection |  |  |  |  |
| user\_registration\_logs | \_id | UUID | NO |  | PRIMARY KEY | Định danh chuẩn UUID v7 để tối ưu sắp xếp thời gian. |
| user\_registration\_logs | tenant\_id | UUID | NO |  |  | ID của tổ chức mà người dùng tham gia. |
| user\_registration\_logs | user\_id | UUID | NO |  |  | ID gốc của người dùng bên bảng users. |
| user\_registration\_logs | registration\_source | Enum8(...) | NO | DIRECT' | DIRECT'=1, 'SSO'=2, 'INVITE'=3 | Nguồn đăng ký (Trực tiếp, qua SSO, hoặc được mời). |
| user\_registration\_logs | data\_region | String | NO |  |  | Vùng lưu trữ dữ liệu (VD: ap-southeast-1). |
| user\_registration\_logs | created\_at | DateTime64(3) | NO | now() | UTC | Thời điểm đăng ký chính xác đến mili-giây. |
| Nhóm Billing & FinOps |  | Package |  |  |  |  |
| Danh mục Sản phẩm & Gói dịch vụ |  | Package |  |  |  | Đây là nơi quy định các "nguyên liệu" đầu vào của hệ thống trước khi đóng gói thành các gói cước thương mại. |
| saas\_product\_types | YSQL | Collection |  |  |  | danh mục định nghĩa các phân loại sản phẩm thương mại của nền tảng |
| saas\_product\_types | \_id | UUID | NO | - | PRIMARY KEY (v7) | Định danh duy nhất, hỗ trợ sắp xếp theo thời gian. |
| saas\_product\_types | code | VARCHAR(50) | NO | - | UNIQUE, CHECK (code \~ '^[A-Z0-9\_]+$') | Mã định danh kỹ thuật (VD: APP, DOMAIN, SSL). Chỉ chứa chữ hoa và gạch dưới. |
| saas\_product\_types | name | TEXT | NO | - | CHECK (LENGTH(name) > 0) | Tên hiển thị của loại sản phẩm (VD: Phần mềm, Tên miền). |
| saas\_product\_types | description | TEXT | YES | NULL | - | Mô tả chi tiết về cách hệ thống xử lý loại sản phẩm này. |
| saas\_product\_types | is\_active | BOOLEAN | NO | TRUE | - | Trạng thái cho phép sử dụng loại sản phẩm này để tạo sản phẩm mới. |
| saas\_product\_types | created\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm tạo bản ghi. |
| saas\_product\_types | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| saas\_product\_types | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking ngăn chặn ghi đè dữ liệu đồng thời. |
| saas\_products | YSQL | Collection |  |  |  | (Dòng sản phẩm): Lưu trữ thông tin về các dòng sản phẩm lớn của doanh nghiệp (ví dụ: "Bộ giải pháp Nhân sự", "Hệ thống CRM"). Bảng này bao gồm mã sản phẩm, tên, mô tả và các thuộc tính cơ bản. |
| saas\_products | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và tối ưu sharding,. |
| saas\_products | code | VARCHAR(50) | NO |  | UNIQUE, CHECK (\~ '^[a-z0-9-]+$') | Mã dòng sản phẩm (Slug). Ví dụ: hrm-suite, crm-platform. Chỉ chứa chữ thường, số và gạch ngang,. |
| saas\_products | name | TEXT | NO |  | CHECK (length(name) > 0) | Tên sản phẩm hiển thị. |
| saas\_products | product\_type | VARCHAR(20) | NO | APP' | REFERENCES saas\_product\_types(code) | Phân loại sản phẩm để xử lý logic: Ứng dụng, Tên miền, SSL hoặc Dịch vụ tư vấn. |
| saas\_products | description | TEXT | YES | NULL |  | Mô tả chi tiết sản phẩm. Dùng TEXT để không giới hạn độ dài,. |
| saas\_products | base\_price | NUMERIC(19,4) | NO | 0 | CHECK (base\_price >= 0) | Giá niêm yết cơ bản. Sử dụng NUMERIC để đảm bảo chính xác tuyệt đối trong tài chính,. |
| saas\_products | currency | VARCHAR(3) | NO | VND' | CHECK (length(currency) = 3) | Mã tiền tệ theo chuẩn ISO 4217 (VND, USD,...),. |
| saas\_products | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái cho phép kinh doanh sản phẩm này,. |
| saas\_products | metadata | JSONB | NO | {}' |  | Chứa các thông tin động, thuộc tính riêng biệt tùy theo loại sản phẩm,. |
| saas\_products | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (chuẩn UTC),. |
| saas\_products | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| saas\_products | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Hỗ trợ Soft Delete để bảo toàn dữ liệu lịch sử. |
| saas\_products | version | BIGINT | NO | 1 | CHECK (version >= 1) | Sử dụng cho Optimistic Locking, ngăn chặn ghi đè dữ liệu khi nhiều người cùng sửa,. |
| applications | YSQL | Collection |  |  |  | (Danh sách ứng dụng): Định nghĩa các đơn vị phần mềm kỹ thuật cụ thể (ví dụ: "App Tuyển dụng", "App Chấm công", "App Quản lý kho"). |
| applications | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp sắp xếp theo thời gian,. |
| applications | code | VARCHAR(50) | NO |  | UNIQUE, CHECK (code \~ '^[A-Z0-9\_]+$') | Mã ứng dụng kỹ thuật (VD: HRM\_RECRUIT). Chỉ chứa chữ hoa, số và gạch dưới. |
| applications | name | VARCHAR(255) | NO |  | CHECK (length(name) > 0) | Tên hiển thị của ứng dụng. |
| applications | description | TEXT | YES | NULL |  | Mô tả chi tiết chức năng của ứng dụng. |
| applications | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái bật/tắt ứng dụng trên toàn hệ thống,. |
| applications | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (chuẩn UTC),. |
| applications | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật dữ liệu gần nhất. |
| applications | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm xóa mềm (Soft Delete). |
| applications | version | BIGINT | NO | 1 | CHECK (version >= 1) | Dùng cho cơ chế Optimistic Locking, chống ghi đè dữ liệu đồng thời. |
| app\_capabilities | YSQL | Collection |  |  |  | (Định nghĩa tính năng & giới hạn): Lưu danh sách các tính năng (Boolean) và giới hạn (Number) mà từng ứng dụng hỗ trợ (ví dụ: max\_users, storage\_gb). |
| app\_capabilities | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| app\_capabilities | app\_code | VARCHAR(50) | NO |  | REFERENCES applications(code) | Tham chiếu đến mã ứng dụng kỹ thuật. |
| app\_capabilities | code | VARCHAR(50) | NO |  | CHECK (code \~ '^[a-z0-9\_]+$') | Mã định danh tính năng/hạn mức (VD: allow\_sso, max\_users). |
| app\_capabilities | name | VARCHAR(255) | NO |  | CHECK (length(name) > 0) | Tên hiển thị của khả năng. |
| app\_capabilities | type | VARCHAR(20) | NO |  | CHECK (type IN ('BOOLEAN', 'NUMBER')) | Phân loại: BOOLEAN (Tính năng) hoặc NUMBER (Hạn mức). |
| app\_capabilities | default\_value | JSONB | NO |  |  | Giá trị mặc định (VD: true hoặc 10). Dùng JSONB để linh hoạt kiểu dữ liệu. |
| app\_capabilities | description | TEXT | YES | NULL |  | Mô tả chi tiết về tính năng hoặc hạn mức này. |
| app\_capabilities | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái cho phép sử dụng khả năng này để đóng gói. |
| app\_capabilities | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (chuẩn UTC). |
| app\_capabilities | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| app\_capabilities | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Hỗ trợ Soft Delete (Xóa mềm). |
| app\_capabilities | version | BIGINT | NO | 1 | CHECK (version >= 1) | Sử dụng cho Optimistic Locking. |
| service\_packages | YSQL | Collection |  |  |  | (Danh mục gói cước): Định nghĩa các gói Combo bán hàng (ví dụ: Gói Starter, Pro, Enterprise). Bảng này sử dụng cột included\_apps\_config dạng JSONB để lưu cấu hình các ứng dụng và giới hạn mặc định đi kèm trong gói. |
| service\_packages | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| service\_packages | saas\_product\_id | UUID | NO |  | REFERENCES products(\_id) | Thuộc dòng sản phẩm chính nào (VD: Bộ giải pháp Nhân sự). |
| service\_packages | code | VARCHAR(50) | NO |  | UNIQUE, CHECK (code \~ '^[a-z0-9-]+$') | Mã gói cước (Slug). Chỉ chứa chữ thường, số, gạch ngang (VD: hrm-pro-monthly). |
| service\_packages | name | VARCHAR(255) | NO |  | CHECK (length(name) > 0) | Tên gói cước hiển thị trên báo giá/hóa đơn. |
| service\_packages | description | TEXT | YES | NULL |  | Mô tả chi tiết các quyền lợi của gói cước. |
| service\_packages | price\_amount | NUMERIC(19,4) | NO | 0 | CHECK (price\_amount >= 0) | Giá niêm yết của gói. Dùng NUMERIC để đảm bảo chính xác tuyệt đối. |
| service\_packages | currency\_code | VARCHAR(3) | NO | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ theo chuẩn ISO 4217. |
| service\_packages | entitlements\_config | JSONB | NO | {}' |  | Chứa cấu hình lồng nhau về Apps, Features và Limits (VD: Gói này có HRM và CRM).<br><br>Một bản ghi entitlements\_config điển hình cho một gói "Combo Enterprise" có thể trông như sau:<br>{<br>"HRM\_RECRUIT": {<br>"features": {<br>"ai\_screening": true,<br>"custom\_email": true<br>},<br>"limits": {<br>"job\_posts": 100,<br>"cv\_storage": 50<br>}<br>},<br>"HRM\_TIMEKEEPING": {<br>"features": {<br>"face\_id": true<br>},<br>"limits": {<br>"max\_locations": 5<br>}<br>}<br>} |
| service\_packages | status | VARCHAR(20) | NO | ACTIVE' | CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')) | Trạng thái gói: Đang bán, Ngừng bán, hoặc Lưu trữ. |
| service\_packages | is\_public | BOOLEAN | NO | TRUE |  | Gói cước công khai hay gói thiết kế riêng (Custom) cho khách VIP. |
| service\_packages | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo gói (UTC). |
| service\_packages | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| service\_packages | deleted\_at | TIMESTAMPTZ | YES | NULL |  | Hỗ trợ Soft Delete để bảo toàn dữ liệu lịch sử. |
| service\_packages | version | BIGINT | NO | 1 | CHECK (version >= 1) | Dùng cho Optimistic Locking, ngăn chặn ghi đè khi nhiều Admin cùng sửa. |
| Quản lý Thuê bao (Subscriptions - Fixed Billing) |  | Package |  |  |  |  |
| tenant\_subscriptions | YSQL | Collection |  |  |  | (Thuê bao hiện hành): Đây là bảng quan trọng nhất, lưu trữ thông tin gói cước mà khách hàng đang sử dụng |
| tenant\_subscriptions | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và tối ưu Sharding,. |
| tenant\_subscriptions | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định thuê bao này thuộc về khách hàng nào. |
| tenant\_subscriptions | package\_id | UUID | NO |  | FOREIGN KEY tham chiếu service\_packages(\_id) | Tham chiếu gói cước gốc để đối soát và báo cáo doanh thu. |
| tenant\_subscriptions | price\_amount | NUMERIC(19,4) | NO | 0 | CHECK (price\_amount >= 0) | Snapshot giá: Lưu giá thực tế tại thời điểm mua để tránh biến động khi gói gốc đổi giá,. |
| tenant\_subscriptions | currency\_code | VARCHAR(3) | NO | VND' | CHECK (LENGTH = 3) | Mã tiền tệ theo chuẩn ISO 4217,. |
| tenant\_subscriptions | granted\_entitlements | JSONB | NO | {}' |  | Snapshot quyền lợi: Chứa cấu hình chi tiết Features/Limits của từng App. Cho phép ghi đè (Override) khi mua thêm Add-on,. |
| tenant\_subscriptions | granted\_app\_codes | TEXT[] | YES |  | GENERATED ALWAYS AS (...) STORED | Cache mảng: Trích xuất các Key từ JSONB để kiểm tra quyền truy cập App cực nhanh bằng GIN Index,. |
| tenant\_subscriptions | start\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm bắt đầu có hiệu lực (UTC),. |
| tenant\_subscriptions | end\_at | TIMESTAMPTZ | YES |  | CHECK (end\_at > start\_at) | Thời điểm hết hạn. NULL nếu là gói vĩnh viễn,. |
| tenant\_subscriptions | status | VARCHAR(20) | NO | ACTIVE' | CHECK (IN ('ACTIVE', 'EXPIRED', 'CANCELLED', 'PAST\_DUE')) | Trạng thái của thuê bao,. |
| tenant\_subscriptions | version | BIGINT | NO | 1 |  | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời khi có nhiều giao dịch. |
| tenant\_subscriptions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (Audit). |
| tenant\_subscriptions | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_subscriptions | deleted\_at | TIMESTAMPTZ | YES |  |  | Hỗ trợ Soft Delete để khôi phục dữ liệu khi cần,. |
| subscription\_invoices | YSQL | Collection |  |  |  | (Hóa đơn thuê bao): Lưu trữ lịch sử hóa đơn, số tiền, trạng thái thanh toán và mã tiền tệ (ISO 4217) |
| subscription\_invoices | \_id | UUID | NO |  | PRIMARY KEY | Định danh hóa đơn chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| subscription\_invoices | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định hóa đơn thuộc về khách hàng nào. Cần thiết để sharding/filtering. |
| subscription\_invoices | order\_id | UUID | YES |  | FK tham chiếu subscription\_orders(\_id) | Liên kết tới đơn hàng gốc (nếu hóa đơn phát sinh từ hành động mua/nâng cấp). |
| subscription\_invoices | subscription\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết hóa đơn với gói thuê bao cụ thể của khách hàng. |
| subscription\_invoices | invoice\_number | VARCHAR(50) | NO |  | UNIQUE | Mã hóa đơn nghiệp vụ (VD: INV-2024-0001) để đối soát với kế toán. |
| subscription\_invoices | subtotal | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền hàng trước thuế và giảm giá. |
| subscription\_invoices | tax\_amount | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền thuế (VAT/GST). |
| subscription\_invoices | discount\_amount | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền được giảm giá. |
| subscription\_invoices | total\_amount | NUMERIC(19,4) | NO | 0 | total = sub + tax - discount | Tổng tiền phải thanh toán (Final Amount). |
| subscription\_invoices | amount\_paid | NUMERIC(19,4) | NO | 0 | \>= 0 | Số tiền khách đã thanh toán thực tế. |
| subscription\_invoices | amount\_due | NUMERIC(19,4) | NO | 0 | due = total - paid | Số tiền còn nợ (Hỗ trợ thanh toán một phần). |
| subscription\_invoices | customer\_snapshot | JSONB | NO | {}' |  | Quan trọng: Lưu tên công ty, MST, địa chỉ tại thời điểm xuất hóa đơn. |
| subscription\_invoices | items\_snapshot | JSONB | NO | []' |  | Danh sách sản phẩm/dịch vụ, đơn giá, số lượng tại thời điểm mua (Snapshot). |
| subscription\_invoices | tax\_breakdown | JSONB | NO | []' |  | Chi tiết các loại thuế áp dụng (VD: VAT 10%, Thuế nhà thầu 5%). |
| subscription\_invoices | billing\_period\_start | TIMESTAMPTZ | NO |  |  | Ngày bắt đầu chu kỳ tính tiền (UTC). |
| subscription\_invoices | billing\_period\_end | TIMESTAMPTZ | NO |  | CHECK (end > start) | Ngày kết thúc chu kỳ tính tiền (UTC). |
| subscription\_invoices | currency\_code | VARCHAR(3) | NO | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ ISO 4217 (VND, USD,...). |
| subscription\_invoices | status | VARCHAR(20) | NO | OPEN' | CHECK (IN ('DRAFT', 'OPEN', 'PAID', 'VOID', 'UNCOLLECTIBLE')) | Trạng thái hóa đơn: Nháp, Đang mở, Đã trả, Hủy, Nợ xấu. |
| subscription\_invoices | due\_date | TIMESTAMPTZ | NO |  |  | Hạn chót thanh toán. |
| subscription\_invoices | paid\_at | TIMESTAMPTZ | YES |  |  | Thời điểm thực tế khách hàng thanh toán thành công. |
| subscription\_invoices | price\_adjustments | JSONB | NO | []' |  | Lưu chi tiết giảm giá, chiết khấu để minh bạch hóa đơn,. |
| subscription\_invoices | metadata | JSONB | NO | {}' |  | Lưu thông tin bổ sung tùy linh hoạt (VD: ghi chú, thông tin Gateway). |
| subscription\_invoices | pdf\_url | TEXT | YES |  |  | Link file PDF hóa đơn lưu trữ trên S3. |
| subscription\_invoices | version | BIGINT | NO | 1 | CHECK (version >= 1) | Dùng cho Optimistic Locking chống ghi đè dữ liệu. |
| subscription\_invoices | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo hóa đơn. |
| subscription\_invoices | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| subscription\_invoices | deleted\_at | TIMESTAMPTZ | YES |  |  | Hỗ trợ Soft Delete để xóa mềm. |
| subscription\_orders | YSQL | Collection |  |  |  | (Lệnh mua gói): Ghi lại các lệnh thực hiện mua hoặc nâng cấp gói cước từ phía Tenant. |
| subscription\_orders | \_id | UUID | NO |  | PRIMARY KEY | Định danh đơn hàng chuẩn UUID v7. |
| subscription\_orders | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định đơn hàng thuộc về khách hàng nào. |
| subscription\_orders | type | VARCHAR(20) | NO | NEW' | CHECK (IN ('NEW', 'RENEWAL', 'UPGRADE', 'DOWNGRADE', 'ADD\_ON')) | Phân loại tính chất đơn hàng để tính toán doanh thu. |
| subscription\_orders | order\_number | VARCHAR(50) | NO |  | UNIQUE | Mã đơn hàng nghiệp vụ (VD: ORD-2024-1029) để đối soát. |
| subscription\_orders | po\_number | VARCHAR(50) | YES |  |  | Số Purchase Order (Yêu cầu bắt buộc với khách hàng Enterprise). |
| subscription\_orders | subtotal\_amount | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền hàng trước thuế và giảm giá. |
| subscription\_orders | discount\_amount | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền được giảm (Voucher/Khuyến mãi). |
| subscription\_orders | tax\_amount | NUMERIC(19,4) | NO | 0 | \>= 0 | Tổng tiền thuế. |
| subscription\_orders | credit\_applied | NUMERIC(19,4) | NO | 0 | \>= 0 | Số tiền trừ từ ví tín dụng (tenant\_wallets). |
| subscription\_orders | total\_amount | NUMERIC(19,4) | NO | 0 | CHECK (total\_amount >= 0) | Tổng số tiền đơn hàng. Chính xác 4 số lẻ. |
| subscription\_orders | currency\_code | VARCHAR(3) | NO | VND' | CHECK (length = 3) | Mã tiền tệ ISO 4217 (VND, USD...). |
| subscription\_orders | status | VARCHAR(20) | NO | PENDING' | CHECK (IN ('DRAFT', 'PENDING', 'PAID', 'FAILED', 'CANCELLED', 'REFUNDED')) | Trạng thái vòng đời đơn hàng. |
| subscription\_orders | items\_snapshot | JSONB | NO | []' |  | Danh sách sản phẩm, đơn giá, số lượng tại thời điểm mua (Immutable). |
| subscription\_orders | billing\_info | JSONB | NO | {}' |  | Snapshot thông tin xuất hóa đơn (Tên công ty, MST, Địa chỉ) tại thời điểm đặt hàng. |
| subscription\_orders | payment\_ref\_id | VARCHAR(100) | YES |  |  | Mã giao dịch từ cổng thanh toán (Stripe PaymentIntent ID, PayPal ID). |
| subscription\_orders | payment\_method | VARCHAR(30) | YES |  |  | Phương thức: CREDIT\_CARD, BANK\_TRANSFER, WALLET. |
| subscription\_orders | metadata | JSONB | NO | {}' |  | Thông tin mở rộng (IP đặt hàng, User Agent...). |
| subscription\_orders | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking chống ghi đè dữ liệu. |
| subscription\_orders | created\_by | UUID | YES |  | FOREIGN KEY tham chiếu users(\_id) | Người dùng thực hiện lệnh đặt hàng. |
| subscription\_orders | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo đơn hàng (UTC). |
| subscription\_orders | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| subscription\_orders | deleted\_at | TIMESTAMPTZ | YES |  |  | Hỗ trợ Soft Delete. |
| usage\_events | ClickHouse | Collection |  |  |  | Lưu nhật ký thô về mọi hành động tiêu dùng tài nguyên của Tenant (ví dụ: số lần gọi API, dung lượng bandwidth). Dữ liệu ở đây mang tính chất Append-only và có khối lượng cực lớn. |
| usage\_events | \_id | UUID | NO |  | Khóa chính logic (UUID v7). | Định danh duy nhất cho sự kiện, sinh từ ứng dụng. |
| usage\_events | tenant\_id | UUID | NO |  | Thành phần của Sorting Key. | Xác định sự kiện thuộc về khách hàng nào. |
| usage\_events | subscription\_id | UUID | NO |  | Dùng để đối soát với YugabyteDB. | Liên kết trực tiếp với gói thuê bao hiện hành của khách. |
| usage\_events | app\_code | String | NO |  | Thành phần của Sorting Key. | Mã ứng dụng phát sinh tiêu dùng (VD: 'LMS', 'CRM'). |
| usage\_events | event\_type | Enum8 / String | NO |  | VD: 'EMAIL\_SENT', 'FILE\_UPLOAD'. | Loại hành động tiêu dùng để áp giá. |
| usage\_events | quantity | Decimal128(4) | NO | 0 | Chính xác 4 số lẻ. | Số lượng tiêu dùng thực tế (VD: 1.5 GB, 100 tin nhắn). |
| usage\_events | unit | String | NO |  | VD: 'GB', 'UNIT', 'REQ' | Đơn vị tính của lượng tiêu dùng. |
| usage\_events | metadata | String | NO | {}' | Lưu dưới dạng chuỗi JSON. | Chứa thông tin bổ sung tùy biến (IP, UserID, Device). |
| usage\_events | data\_region | String | NO | DEFAULT' | Phục vụ luật Data Residency. | Vùng dữ liệu vật lý phát sinh sự kiện. |
| usage\_events | timestamp | DateTime64(3) | NO | now() | Độ chính xác mili-giây (UTC). | Thời điểm chính xác sự kiện xảy ra. |
| tenant\_usages | YSQL | Collection |  |  |  | Dữ liệu tổng hợp từ ClickHouse sau khi qua các Job xử lý định kỳ. Bảng này tách biệt việc ghi log tải cao (ClickHouse) và việc tính tiền chính xác (YugabyteDB), giúp hệ thống xuất hóa đơn không bị chậm. |
| tenant\_usages | \_id | UUID | NO |  | PRIMARY KEY | Định danh chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và sharding,. |
| tenant\_usages | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định dữ liệu tiêu dùng thuộc về khách hàng nào,. |
| tenant\_usages | subscription\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết với gói thuê bao cụ thể để áp giá Metering,. |
| tenant\_usages | usage\_period\_start | TIMESTAMPTZ | NO |  |  | Bắt đầu chu kỳ tổng hợp dữ liệu (UTC),. |
| tenant\_usages | usage\_period\_end | TIMESTAMPTZ | NO |  | CHECK (usage\_period\_end > usage\_period\_start) | Kết thúc chu kỳ tổng hợp dữ liệu (UTC). |
| tenant\_usages | metrics\_data | JSONB | NO | {}' |  | Chứa các chỉ số tiêu dùng (VD: {"emails\_sent": 150, "storage\_gb": 10}),. |
| tenant\_usages | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'BILLED', 'VOID')) | Trạng thái tính tiền: Chờ xử lý, Đã xuất hóa đơn, Hủy bỏ,. |
| tenant\_usages | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm hệ thống ghi nhận bản ghi tổng hợp. |
| tenant\_usages | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_wallets | YSQL | Collection |  |  |  | (Ví tiền của Tenant): Quản lý số dư tiền nạp trước (Prepaid) của khách hàng để trừ dần theo mô hình FinOps,. |
| tenant\_wallets | \_id | UUID | NO |  | PRIMARY KEY | Định danh ví duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| tenant\_wallets | tenant\_id | UUID | NO |  | UNIQUE, FOREIGN KEY tham chiếu tenants(\_id) | Mỗi khách hàng (Tenant) chỉ sở hữu duy nhất một ví chính. |
| tenant\_wallets | balance | NUMERIC(19, 4) | NO | 0 | CHECK (balance >= 0) | Số dư khả dụng. Sử dụng NUMERIC(19, 4) để chính xác tuyệt đối 4 số lẻ. |
| tenant\_wallets | currency\_code | VARCHAR(3) | NO | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ theo chuẩn ISO 4217 (VND, USD,...). |
| tenant\_wallets | is\_frozen | BOOLEAN | NO | FALSE |  | Nếu TRUE, ví bị đóng băng (không cho phép thanh toán) do nghi ngờ gian lận. |
| tenant\_wallets | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu tài chính đồng thời. |
| tenant\_wallets | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm khởi tạo ví (chuẩn UTC). |
| tenant\_wallets | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật số dư gần nhất. |
| wallet\_transactions | YSQL | Collection |  |  |  | (Giao dịch ví): Nhật ký bất biến (Immutable) ghi lại mọi biến động nạp, trừ hoặc hoàn tiền trong ví,. |
| wallet\_transactions | \_id | UUID | NO |  | PRIMARY KEY | Định danh giao dịch duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian,. |
| wallet\_transactions | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định giao dịch thuộc về khách hàng nào để Sharding/Filtering,. |
| wallet\_transactions | wallet\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenant\_wallets(\_id) | Liên kết trực tiếp với ví thực hiện biến động. |
| wallet\_transactions | type | VARCHAR(30) | NO |  | CHECK (type IN ('DEPOSIT', 'USAGE\_DEDUCT', 'REFUND', 'BONUS')) | Loại giao dịch: Nạp tiền, Trừ phí sử dụng, Hoàn tiền, Tặng thưởng,. |
| wallet\_transactions | amount | NUMERIC(19, 4) | NO |  | CHECK (amount <> 0) | Số tiền biến động. Dùng NUMERIC(19, 4) để chính xác tuyệt đối,. |
| wallet\_transactions | balance\_after | NUMERIC(19, 4) | NO |  | CHECK (balance\_after >= 0) | Snapshot số dư: Số dư ví ngay sau khi thực hiện giao dịch này để đối soát. |
| wallet\_transactions | reference\_id | UUID | YES |  |  | Liên kết tới hóa đơn (invoices) hoặc đơn hàng (orders) phát sinh giao dịch. |
| wallet\_transactions | description | TEXT | YES |  |  | Mô tả chi tiết nội dung giao dịch (VD: "Trừ phí gửi 5000 email"). |
| wallet\_transactions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm phát sinh giao dịch chuẩn UTC,. |
| license\_allocations | YSQL | Collection |  |  |  | (Phân bổ giấy phép): Quản lý số lượng "ghế" (seats) hoặc giấy phép đã mua so với số lượng đã gán thực tế cho nhân viên,. |
| license\_allocations | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| license\_allocations | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định hạn ngạch thuộc về khách hàng nào. |
| license\_allocations | subscription\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết trực tiếp với gói thuê bao hoặc hóa đơn đã mua. |
| license\_allocations | license\_type | VARCHAR(30) | NO | BILLABLE' | CHECK (IN ('BILLABLE', 'GUEST', 'READ\_ONLY')) | Loại giấy phép: Tính phí, Khách, hoặc Chỉ đọc. |
| license\_allocations | purchased\_quantity | INTEGER | NO | 0 | CHECK (>= 0) | Tổng số lượng "ghế" khách hàng đã thanh toán. |
| license\_allocations | assigned\_quantity | INTEGER | NO | 0 | CHECK (assigned\_quantity <= purchased\_quantity) | Số lượng thực tế đã gán cho người dùng. Không được vượt quá số mua. |
| license\_allocations | status | VARCHAR(20) | NO | ACTIVE' | CHECK (IN ('ACTIVE', 'EXPIRED', 'SUSPENDED')) | Trạng thái của hạn ngạch giấy phép. |
| license\_allocations | expires\_at | TIMESTAMPTZ | YES |  |  | Thời điểm hết hạn của giấy phép này (thường khớp với gói cước). |
| license\_allocations | version | BIGINT | NO | 1 |  | Optimistic Locking để ngăn chặn gán quyền đồng thời gây vượt hạn ngạch. |
| license\_allocations | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| license\_allocations | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| price\_adjustments | YSQL | Collection |  |  |  | (Điều chỉnh giá): Lưu trữ các thông tin chiết khấu hoặc giảm giá tùy chỉnh cho từng hóa đơn để đảm bảo tính minh bạch. |
| price\_adjustments | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| price\_adjustments | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định khoản điều chỉnh này thuộc về khách hàng nào. |
| price\_adjustments | subscription\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết với một thuê bao cụ thể của khách hàng. |
| price\_adjustments | invoice\_id | UUID | YES |  | FOREIGN KEY tham chiếu subscription\_invoices(\_id) | Liên kết với hóa đơn cụ thể (nếu điều chỉnh theo từng kỳ thanh toán). |
| price\_adjustments | type | VARCHAR(20) | NO |  | CHECK (type IN ('DISCOUNT', 'SURCHARGE', 'TAX', 'REBATE')) | Loại điều chỉnh: Giảm giá, phụ phí, thuế, hoặc hoàn tiền. |
| price\_adjustments | amount | NUMERIC(19,4) | NO | 0 | CHECK (amount >= 0) | Giá trị tuyệt đối của khoản điều chỉnh. |
| price\_adjustments | currency\_code | VARCHAR(3) | NO | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ ISO 4217. |
| price\_adjustments | reason | TEXT | NO |  | CHECK (length(reason) > 0) | Lý do điều chỉnh (VD: "Giảm giá khách hàng thân thiết", "Phí quá hạn"). |
| price\_adjustments | source | VARCHAR(30) | NO | MANUAL' |  | Nguồn gốc: MANUAL (Admin nhập), COUPON, AUTOMATIC\_POLICY. |
| price\_adjustments | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking. |
| price\_adjustments | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| price\_adjustments | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| saas\_business\_reports | ClickHouse | Collection |  |  |  | Báo cáo doanh thu: Các bảng tổng hợp phục vụ việc truy vấn báo cáo doanh thu theo năm hoặc xu hướng khách hàng với tốc độ mili-giây,. |
| saas\_business\_reports | \_id | UUID | NO |  | Khóa chính logic (UUID v7) | Định danh duy nhất cho bản ghi báo cáo. |
| saas\_business\_reports | partner\_id | Nullable(UUID) | YES | NULL |  | ID của đối tác phân phối (nếu báo cáo thuộc một kênh cụ thể) [Lịch sử trò chuyện]. |
| saas\_business\_reports | report\_date | Date32 | NO |  | Thành phần của Sorting Key | Ngày tham chiếu của dữ liệu báo cáo (YYYY-MM-DD),. |
| saas\_business\_reports | revenue\_category | Enum8 | NO |  | NEW' = 1, 'RENEWAL' = 2, 'UPGRADE' = 3, 'ADD\_ON' = 4, 'COMMISSION' = 5 | Phân loại doanh thu để nén dữ liệu cực tốt,. |
| saas\_business\_reports | total\_revenue | Decimal128(4) | NO | 0 | Chính xác tuyệt đối 4 số lẻ | Tổng doanh thu hệ thống của hạng mục đó trong ngày,. |
| saas\_business\_reports | currency\_code | FixedString(3) | NO | VND' | Chuẩn ISO 4217 | Mã tiền tệ (VND, USD,...),. |
| saas\_business\_reports | tenant\_count | UInt32 | NO | 0 |  | Số lượng khách hàng đóng góp vào doanh thu này. |
| saas\_business\_reports | details\_json | String | NO | {}' | Dữ liệu dạng JSON String | Chi tiết doanh thu theo từng gói (Pro, Enterprise,...),. |
| saas\_business\_reports | created\_at | DateTime64(3) | NO | now() | Độ chính xác mili-giây | Thời điểm hệ thống sinh báo cáo (UTC),. |
| Quản lý cung cấp dịch vụ |  | Package |  |  |  |  |
| digital\_asset\_types | YSQL | Collection |  |  |  | Loại tài sản số |
| digital\_asset\_types | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 [Source 2, 4]. |
| digital\_asset\_types | code | VARCHAR(50) | NO |  | UNIQUE, CHECK | Mã loại tài sản (VD: DOMAIN, SSL, SMTP\_IP). Dùng làm khóa ngoại logic [Source 103, 113]. |
| digital\_asset\_types | name | TEXT | NO |  |  | Tên hiển thị (VD: "Tên miền Quốc tế"). |
| digital\_asset\_types | description | TEXT | YES | NULL |  | Mô tả chi tiết loại tài sản. |
| digital\_asset\_types | provider\_config | JSONB | NO | {}' |  | Cấu hình kết nối với nhà cung cấp (VD: API Endpoint của GoDaddy hay Let's Encrypt) [Source 15, 84]. |
| digital\_asset\_types | attributes\_schema | JSONB | NO | {}' |  | Quan trọng: Định nghĩa JSON Schema để validate dữ liệu đầu vào trong bảng tenant\_digital\_assets (VD: Bắt buộc phải có nameservers nếu là Domain) [Source 1263]. |
| digital\_asset\_types | is\_renewable | BOOLEAN | NO | TRUE |  | Cờ đánh dấu tài sản này có cần gia hạn định kỳ hay mua đứt một lần [Source 84, 85]. |
| digital\_asset\_types | provisioning\_job | VARCHAR(100) | YES | NULL |  | Tên của Worker/Job sẽ xử lý việc cấp phát tài sản này (VD: JobRegisterDomain) [Source 1595, 1596]. |
| digital\_asset\_types | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo [Source 16, 17]. |
| digital\_asset\_types | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| digital\_asset\_types | version | BIGINT | NO | 1 | CHECK (>= 1) | Optimistic Locking [Source 16]. |
| tenant\_digital\_assets | YSQL | Collection |  |  |  | Tài sàn số |
| tenant\_digital\_assets | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và tối ưu Sharding [Source 469]. |
| tenant\_digital\_assets | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định tài sản này thuộc sở hữu của khách hàng nào [Source 469]. |
| tenant\_digital\_assets | order\_id | UUID | YES | NULL | REFERENCES subscription\_orders(\_id) | Liên kết với đơn hàng mua tài sản này (để truy vết nguồn gốc) [Source 469]. |
| tenant\_digital\_assets | asset\_type | VARCHAR(50) | NO |  | CHECK (asset\_type IN ('DOMAIN', 'SSL', 'LICENSE\_KEY', 'DEDICATED\_IP')) | Phân loại tài sản để hệ thống xử lý logic Provisioning tương ứng [Source 469]. |
| tenant\_digital\_assets | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên định danh tài sản (VD: example.com, Wildcard SSL, License #123) [Source 469]. |
| tenant\_digital\_assets | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'PROVISIONING', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'TRANSFERRING')) | Trạng thái vòng đời của tài sản [Source 470, 1311]. |
| tenant\_digital\_assets | auto\_renew | BOOLEAN | NO | TRUE |  | Cờ bật/tắt tự động gia hạn (trừ tiền trong ví) khi hết hạn [Source 470]. |
| tenant\_digital\_assets | asset\_metadata | JSONB | NO | {}' |  | Chứa thông tin kỹ thuật đặc thù (VD: Registrar Info, Auth Code, CSR, IP Address) [Source 470]. |
| tenant\_digital\_assets | activated\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm tài sản được kích hoạt thành công (UTC). |
| tenant\_digital\_assets | expires\_at | TIMESTAMPTZ | YES | NULL | CHECK (expires\_at > activated\_at) | Thời điểm hết hạn. Dùng để chạy Job quét gia hạn [Source 470]. |
| tenant\_digital\_assets | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi. |
| tenant\_digital\_assets | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_digital\_assets | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để tránh xung đột khi cập nhật trạng thái. |
| tenant\_service\_deliveries | YSQL | Collection |  |  |  | Quản lý vòng đời của các dịch vụ chuyên nghiệp (Professional Services) như tư vấn, đào tạo, hoặc triển khai. |
| tenant\_service\_deliveries | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 [Source 1304]. |
| tenant\_service\_deliveries | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định dịch vụ thuộc về khách hàng nào [Source 1304]. |
| tenant\_service\_deliveries | product\_id | UUID | NO |  | REFERENCES saas\_products(\_id) | Tham chiếu đến dòng sản phẩm dịch vụ được định nghĩa trong catalog [Source 1304]. |
| tenant\_service\_deliveries | subscription\_id | UUID | YES | NULL | REFERENCES tenant\_subscriptions(\_id) | Liên kết nếu dịch vụ này là một phần (Add-on) của một gói thuê bao lớn [Source 1305]. |
| tenant\_service\_deliveries | unit\_type | VARCHAR(20) | NO |  | CHECK (unit\_type IN ('HOUR', 'SESSION', 'PROJECT')) | Đơn vị đo lường dịch vụ (Giờ, Buổi, Dự án) [Source 1305]. |
| tenant\_service\_deliveries | total\_units | NUMERIC(15,2) | NO | 0 | CHECK (total\_units > 0) | Tổng số lượng dịch vụ khách hàng đã mua (VD: 10 giờ tư vấn) [Source 1305]. |
| tenant\_service\_deliveries | delivered\_units | NUMERIC(15,2) | NO | 0 | CHECK (delivered\_units <= total\_units) | Số lượng thực tế đã cung cấp/nghiệm thu. Không được vượt quá tổng mua [Source 1305]. |
| tenant\_service\_deliveries | unit\_price | NUMERIC(19,4) | NO |  | CHECK (unit\_price >= 0) | Snapshot giá: Giá mỗi đơn vị tại thời điểm mua để chốt doanh thu, tránh ảnh hưởng khi giá niêm yết thay đổi [Source 1305, 1310]. |
| tenant\_service\_deliveries | currency\_code | VARCHAR(3) | NO | VND' | CHECK (LENGTH(currency\_code) = 3) | Mã tiền tệ ISO 4217 [Source 1306]. |
| tenant\_service\_deliveries | status | VARCHAR(20) | NO | PENDING' | CHECK (status IN ('PENDING', 'IN\_PROGRESS', 'COMPLETED', 'CANCELLED')) | Trạng thái thực hiện dịch vụ [Source 1306]. |
| tenant\_service\_deliveries | service\_metadata | JSONB | NO | {}' |  | Lưu thông tin bổ sung như tên người đào tạo, link tài liệu biên bản nghiệm thu [Source 1306]. |
| tenant\_service\_deliveries | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm mua dịch vụ (UTC) [Source 1306]. |
| tenant\_service\_deliveries | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật tiến độ gần nhất. |
| tenant\_service\_deliveries | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để tránh xung đột khi cập nhật tiến độ. |
| Nhóm Core Logic Hệ thống |  | Package |  |  |  |  |
| tenant\_encryption\_keys | YSQL | Collection |  |  |  | Lưu trữ các khóa mã hóa dữ liệu (DEK) riêng biệt cho từng Tenant. Bảng này hỗ trợ tính năng bảo mật cao cấp như Crypto-shredding (xóa vĩnh viễn dữ liệu bằng cách hủy khóa) |
| tenant\_encryption\_keys | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| tenant\_encryption\_keys | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định khóa thuộc về khách hàng nào. |
| tenant\_encryption\_keys | encrypted\_data\_key | BYTEA | NO |  |  | Khóa DEK đã được mã hóa bởi Master Key (KEK). Lưu dạng nhị phân để bảo mật cao nhất. |
| tenant\_encryption\_keys | key\_version | INTEGER | NO | 1 | CHECK (key\_version >= 1) | Phiên bản của khóa để hỗ trợ xoay vòng khóa (Rotation). |
| tenant\_encryption\_keys | status | VARCHAR(20) | NO | ACTIVE' | CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')) | Trạng thái: Nếu là REVOKED, dữ liệu coi như bị xóa vĩnh viễn (Crypto-shredding). |
| tenant\_encryption\_keys | algorithm | VARCHAR(50) | NO | AES-256-GCM' |  | Thuật toán mã hóa được sử dụng. |
| tenant\_encryption\_keys | rotation\_at | TIMESTAMPTZ | YES |  |  | Thời điểm dự kiến cần xoay vòng khóa tiếp theo. |
| tenant\_encryption\_keys | version | BIGINT | NO | 1 |  | Optimistic Locking để ngăn chặn cập nhật khóa đồng thời. |
| tenant\_encryption\_keys | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo khóa (UTC). |
| tenant\_encryption\_keys | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_i18n\_overrides | YSQL | Collection |  |  |  | Cho phép khách hàng ghi đè các thuật ngữ mặc định của hệ thống để phù hợp với đặc thù ngành nghề (ví dụ: đổi "Nhân viên" thành "Bác sĩ" hoặc "Giáo viên"). |
| tenant\_i18n\_overrides | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất bản ghi (UUID v7), hỗ trợ sắp xếp theo thời gian. |
| tenant\_i18n\_overrides | tenant\_id | UUID | NO |  | FOREIGN KEY tham chiếu tenants(\_id) | Xác định bản ghi thuộc về khách hàng nào. |
| tenant\_i18n\_overrides | locale | VARCHAR(10) | NO | vi-VN' | CHECK (LENGTH(locale) >= 2) | Mã ngôn ngữ/định dạng (VD: 'en-US', 'vi-VN'). |
| tenant\_i18n\_overrides | translation\_key | VARCHAR(255) | NO |  | CHECK (LENGTH(translation\_key) > 0) | Khóa thuật ngữ gốc của hệ thống (VD: 'common.employee'). |
| tenant\_i18n\_overrides | custom\_value | TEXT | NO |  | CHECK (LENGTH(custom\_value) > 0) | Giá trị đã được khách hàng đổi tên. |
| tenant\_i18n\_overrides | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| tenant\_i18n\_overrides | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| tenant\_i18n\_overrides | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cuối cùng. |
| tenant\_i18n\_overrides | created\_by | UUID | YES |  |  | ID người dùng thực hiện tạo bản ghi. |
| system\_jobs | YSQL | Collection |  |  |  | Quản lý hàng đợi các tác vụ nền (Background Jobs) như xuất báo cáo Excel, gửi email hàng loạt hoặc tính toán lương, giúp hệ thống không bị quá tải khi xử lý request. |
| system\_jobs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| system\_jobs | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Xác định công việc thuộc về khách hàng nào để tính phí hoặc giới hạn. |
| system\_jobs | job\_type | VARCHAR(50) | NO |  | CHECK (length > 0) | Loại công việc (VD: EXPORT\_EXCEL, CALCULATE\_PAYROLL). |
| system\_jobs | payload | JSONB | NO | {}' |  | Chứa toàn bộ tham số đầu vào của công việc. |
| system\_jobs | status | VARCHAR(20) | NO | PENDING' | CHECK IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED') | Trạng thái vòng đời của công việc. |
| system\_jobs | scheduled\_at | TIMESTAMPTZ | NO | now() | Lưu chuẩn UTC | Thời điểm dự kiến thực hiện (hỗ trợ hẹn giờ chạy sau). |
| system\_jobs | started\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm bắt đầu thực thi thực tế. |
| system\_jobs | finished\_at | TIMESTAMPTZ | YES | NULL |  | Thời điểm hoàn thành hoặc thất bại. |
| system\_jobs | retry\_count | INT | NO | 0 | CHECK (retry\_count >= 0) | Số lần đã thử lại khi gặp lỗi. |
| system\_jobs | max\_retries | INT | NO | 3 | CHECK (max\_retries >= 0) | Số lần thử lại tối đa cho phép. |
| system\_jobs | last\_error | TEXT | YES | NULL |  | Lưu vết nội dung lỗi cuối cùng để debug. |
| system\_jobs | created\_by | UUID | YES | NULL | FK tham chiếu users(\_id) | ID người dùng đã kích hoạt tác vụ này. |
| system\_jobs | version | BIGINT | NO | 1 |  | Hỗ trợ Optimistic Locking tránh xử lý trùng. |
| feature\_flags | YSQL | Collection |  |  |  | Cho phép bật/tắt các tính năng mới cho từng nhóm khách hàng cụ thể mà không cần triển khai lại mã nguồn (Deploy code). |
| feature\_flags | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất bản ghi theo chuẩn UUID v7,. |
| feature\_flags | flag\_key | VARCHAR(50) | NO |  | UNIQUE, CHECK (length > 0) | Mã kỹ thuật của tính năng (VD: ENABLE\_AI\_WRITING, BETA\_UI),. |
| feature\_flags | description | TEXT | YES | NULL |  | Mô tả chi tiết mục đích của cờ tính năng này. |
| feature\_flags | is\_global\_enabled | BOOLEAN | NO | FALSE |  | Nếu là TRUE, tính năng được bật cho toàn bộ hệ thống bất kể các quy tắc khác,. |
| feature\_flags | rules | JSONB | NO | {}' |  | Chứa logic bật tắt như: tỷ lệ phần trăm (percentage), danh sách tenant được phép (allowed\_tenants), hoặc vùng bị loại trừ (excluded\_regions),. |
| feature\_flags | version | BIGINT | NO | 1 |  | Hỗ trợ Optimistic Locking để ngăn chặn việc ghi đè cấu hình khi nhiều admin cùng chỉnh sửa. |
| feature\_flags | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo cờ (theo chuẩn UTC),. |
| feature\_flags | updated\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm cập nhật cấu hình cuối cùng. |
| tenant\_rate\_limits | YSQL | Collection |  |  |  | (Giới hạn tần suất) Bảng này được thiết kế để bảo vệ hệ thống khỏi việc bị quá tải do một khách hàng sử dụng tài nguyên quá mức |
| tenant\_rate\_limits | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7. |
| tenant\_rate\_limits | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Nếu NULL, đây là cấu hình mặc định toàn sàn (Global Default). |
| tenant\_rate\_limits | api\_group | VARCHAR(50) | NO |  | CHECK (length > 0) | Nhóm API bị giới hạn (VD: 'REPORTING\_API', 'CORE\_API'). |
| tenant\_rate\_limits | limit\_count | INT | NO |  | CHECK (limit\_count > 0) | Số lượng request tối đa được phép. |
| tenant\_rate\_limits | window\_seconds | INT | NO | 60 | CHECK (window\_seconds > 0) | Khung thời gian áp dụng giới hạn (tính bằng giây). |
| tenant\_rate\_limits | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái kích hoạt của quy tắc. |
| tenant\_rate\_limits | description | TEXT | YES | NULL |  | Ghi chú về mục đích của giới hạn này. |
| tenant\_rate\_limits | created\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm tạo bản ghi. |
| tenant\_rate\_limits | updated\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| tenant\_rate\_limits | version | BIGINT | NO | 1 |  | Hỗ trợ Optimistic Locking khi cập nhật cấu hình. |
| tenant\_app\_configs | MongoDB | Collection |  |  |  | chứa các cấu hình vận hành (như màu sắc, logo, ngôn ngữ) thay vì dữ liệu nghiệp vụ |
| tenant\_app\_configs | \_id | String (UUID) | NO | - | Khóa chính, định dạng UUID v7, | Định danh duy nhất, hỗ trợ sắp xếp theo thời gian,. |
| tenant\_app\_configs | tenant\_id | String (UUID) | NO | - | Shard Key, tham chiếu tenants.\_id, | Xác định cấu hình thuộc về khách hàng nào. |
| tenant\_app\_configs | app\_code | String | NO | - | Duy nhất theo cặp (tenant\_id, app\_code) | Mã định danh ứng dụng (VD: 'HRM', 'CRM', 'POS'). |
| tenant\_app\_configs | configs | Object (BSON) | NO | {} | Schema-less (Linh hoạt) | Chứa các cài đặt động như theme\_color, workflow\_steps, logo,. |
| tenant\_app\_configs | version | Int64 | NO | 1 | version >= 1 | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| tenant\_app\_configs | created\_at | Date (ISODate) | NO | now() | Chuẩn UTC, | Thời điểm tạo bản ghi. |
| tenant\_app\_configs | updated\_at | Date (ISODate) | NO | now() | Chuẩn UTC, | Thời điểm cập nhật cuối cùng. |
| system\_announcements | YSQL | Collection |  |  |  | Dùng để gửi thông báo bảo trì, cảnh báo nợ cước hoặc khuyến mãi đến hàng triệu người dùng mà không làm quá tải cơ sở dữ liệu |
| system\_announcements | \_id | UUID | NO | - | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| system\_announcements | titles | JSONB | NO | {}' | Cấu trúc đa ngôn ngữ | Lưu tiêu đề theo locale (VD: {"vi": "Bảo trì", "en": "Maintenance"}) để hỗ trợ đa ngôn ngữ. |
| system\_announcements | contents | JSONB | NO | {}' | Cấu trúc đa ngôn ngữ | Lưu nội dung chi tiết theo locale. Hỗ trợ định dạng Markdown hoặc HTML. |
| system\_announcements | type | VARCHAR(20) | NO | INFO' | CHECK (type IN ('INFO', 'WARNING', 'CRITICAL', 'PROMOTION')) | Phân loại thông báo: Tin tức, Cảnh báo, Bảo trì hoặc Khuyến mãi. |
| system\_announcements | target\_regions | TEXT[] | YES | NULL |  | Mảng chứa danh sách vùng địa lý nhận tin (VD: ['VN\_NORTH']). Nếu NULL là toàn cầu. |
| system\_announcements | target\_plans | TEXT[] | YES | NULL |  | Mảng chứa mã gói cước nhận tin (VD: ['FREE\_TIER']). Nếu NULL là mọi gói. |
| system\_announcements | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái hiển thị của thông báo. |
| system\_announcements | is\_local\_time | BOOLEAN | NO | FALSE |  | Nếu TRUE, thời gian hiển thị sẽ được cộng dời theo múi giờ (timezone) của từng Tenant. |
| system\_announcements | start\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm bắt đầu hiển thị thông báo. |
| system\_announcements | end\_at | TIMESTAMPTZ | YES | NULL | CHECK (end\_at > start\_at) | Thời điểm kết thúc hiển thị. |
| system\_announcements | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking ngăn chặn xung đột khi nhiều Admin cùng sửa cấu hình. |
| system\_announcements | created\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm tạo bản ghi. |
| system\_announcements | updated\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| user\_announcement\_reads | YSQL | Collection |  |  |  | lưu trữ trạng thái "đã đọc" của từng người dùng |
| user\_announcement\_reads | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7. |
| user\_announcement\_reads | tenant\_id | UUID | NO |  | FK tham chiếu tenants(\_id) | Xác định bản ghi thuộc về khách hàng nào để đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| user\_announcement\_reads | user\_id | UUID | NO |  | FK tham chiếu users(\_id) | Người dùng đã thực hiện hành động đọc thông báo. |
| user\_announcement\_reads | announcement\_id | UUID | NO |  | FK tham chiếu system\_announcements(\_id) | ID của thông báo đã được đọc. |
| user\_announcement\_reads | read\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm chính xác người dùng nhấn xem thông báo. |
| user\_announcement\_reads | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| notification\_templates | YSQL | Collection |  |  |  | Mẫu thông báo, hỗ trợ đa kênh như Email (HTML), SMS (Text), Slack (JSON) |
| notification\_templates | \_id | UUID | NO | - | PRIMARY KEY (UUID v7) | Định danh duy nhất cho mẫu. |
| notification\_templates | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Nếu NULL là mẫu chung của hệ thống, nếu có ID là mẫu riêng của khách hàng. |
| notification\_templates | code | VARCHAR(100) | NO | - | Duy nhất theo (tenant\_id, code) | Mã gợi nhớ (VD: 'NEW\_INVOICE', 'PASSWORD\_RESET'). |
| notification\_templates | name | TEXT | NO | - | CHECK (length > 0) | Tên hiển thị của mẫu để quản trị viên dễ nhận biết. |
| notification\_templates | subject\_templates | JSONB | NO | {}' | Cấu trúc đa ngôn ngữ | Lưu tiêu đề (cho Email/Push) theo locale: {"vi": "...", "en": "..."}. |
| notification\_templates | body\_templates | JSONB | NO | {}' | Hỗ trợ HTML/Liquid | Lưu nội dung chi tiết theo locale và kênh (Email, Slack). |
| notification\_templates | sms\_template | TEXT | YES | NULL |  | Nội dung tin nhắn SMS (thường là text thuần). |
| notification\_templates | required\_variables | TEXT[] | YES | {}' |  | Danh sách các biến cần truyền vào (VD: ['user\_name', 'otp\_code']). |
| notification\_templates | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái cho phép sử dụng mẫu này. |
| notification\_templates | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking. |
| notification\_templates | created\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm tạo mẫu. |
| notification\_templates | updated\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| user\_notification\_settings | YSQL | Collection |  |  |  | Người dùng có thể cấu hình để chọn nhận tin qua Email, SMS hay Push cho từng loại thông báo cụ thể (ví dụ: chỉ nhận cảnh báo bảo mật qua SMS, còn tin khuyến mãi chỉ nhận qua App) |
| user\_notification\_settings | \_id | UUID | NO | - | PRIMARY KEY (UUID v7) | Định danh duy nhất cho bản ghi cấu hình. |
| user\_notification\_settings | tenant\_id | UUID | NO | - | FK tham chiếu tenants(\_id) | Xác định cấu hình thuộc về tổ chức nào để đảm bảo cô lập dữ liệu SaaS. |
| user\_notification\_settings | user\_id | UUID | NO | - | FK tham chiếu users(\_id) | Người dùng sở hữu cấu hình nhận thông báo này. |
| user\_notification\_settings | notification\_code | VARCHAR(50) | NO | - | Tham chiếu notification\_templates(code) | Mã loại thông báo (VD: 'NEW\_INVOICE', 'TASK\_ASSIGNED'). |
| user\_notification\_settings | channels | JSONB | NO | {}' | Cấu trúc: {"email": bool, "sms": bool, ...} | Lưu trạng thái bật/tắt của từng kênh nhận tin dưới dạng JSON linh hoạt. |
| user\_notification\_settings | version | BIGINT | NO | 1 | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời. |
| user\_notification\_settings | updated\_at | TIMESTAMPTZ | NO | now() | Chuẩn UTC | Thời điểm cập nhật cấu hình gần nhất phục vụ Audit. |
| Danh mục dùng chung |  | Package |  |  |  |  |
| article\_types | YSQL | Collection |  |  | Loại bài viết |  |
| article\_types | \_id | UUID | NO | PRIMARY KEY | Định danh chuẩn UUID v7. |  |
| article\_types | app\_code | VARCHAR(50) | NO | FK -> applications(code) | Loại bài viết này thuộc ứng dụng nào (VD: CMS\_CORE, HRM\_RECRUIT). |  |
| article\_types | code | VARCHAR(50) | NO | UNIQUE | Mã định danh (VD: NEWS, VIDEO, JOB). |  |
| article\_types | name | TEXT | NO |  | Tên hiển thị mặc định (VD: "Tin tức", "Tuyển dụng"). |  |
| article\_types | icon\_url | TEXT | YES |  | Icon đại diện cho loại bài viết trong Admin Menu. |  |
| article\_types | is\_system | BOOLEAN | NO | FALSE | TRUE: Các loại mặc định của hệ thống, không được xóa. |  |
| article\_types | config\_schema | JSONB | NO | {}' | Cấu trúc dữ liệu đặc thù của loại này (Schema-less definition). |  |
| article\_types | is\_active | BOOLEAN | NO | TRUE | Trạng thái sử dụng. |  |
| article\_types | created\_at | TIMESTAMPTZ | NO | now() | Thời điểm tạo. |  |
| regions | YSQL | Collection |  |  | Các vùng địa lý |  |
| regions | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, giúp sắp xếp theo thời gian và tránh "hotspot" khi ghi phân tán. |
| regions | parent\_id | UUID | YES | NULL | REFERENCES regions(\_id) | ID của vùng cha (VD: Quận Cầu Giấy thuộc TP Hà Nội). Dùng để tạo quan hệ cây. |
| regions | path | TEXT | NO |  |  | Materialized Path (VD: /vn\_id/hn\_id/cg\_id/). Giúp truy vấn "Lấy tất cả phường xã của Hà Nội" cực nhanh bằng LIKE. |
| regions | code | VARCHAR(50) | NO |  | CHECK (length(code) > 0) | Mã hành chính (VD: VN, HAN, 70000). Có thể trùng lặp giữa các quốc gia nên không unique tuyệt đối. |
| regions | name | TEXT | NO |  | CHECK (length(name) > 0) | Tên hiển thị (VD: "Thành phố Hà Nội"). |
| regions | type | VARCHAR(20) | NO |  | CHECK (type IN ('COUNTRY', 'STATE', 'PROVINCE', 'DISTRICT', 'WARD')) | Cấp hành chính. |
| regions | status | VARCHAR(20) | NO | ACTIVE' | CHECK (status IN ('ACTIVE', 'INACTIVE', 'MERGED', 'SPLIT')) | Trạng thái hiện tại của vùng. |
| regions | valid\_from | DATE | NO | 1900-01-01' |  | Ngày bắt đầu có hiệu lực hành chính. |
| regions | valid\_to | DATE | YES | NULL | CHECK (valid\_to > valid\_from) | Ngày hết hiệu lực (nếu đã bị giải thể/sáp nhập). NULL nghĩa là đang hiện hành. |
| regions | histories | JSONB | NO | []' |  | Lưu trữ lịch sử: Mảng các object chứa snapshot dữ liệu cũ mỗi khi có thay đổi (Tên, mã, cha...). |
| regions | metadata | JSONB | NO | {}' |  | Lưu thông tin mở rộng: Zipcode, Dân số, Tọa độ trung tâm, Tên quốc tế (name\_en). |
| regions | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo bản ghi (UTC). |
| regions | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| regions | version | BIGINT | NO | 1 | CHECK (version >= 1) | Optimistic Locking để tránh xung đột khi nhiều admin cùng chỉnh sửa. |
| pages | YSQL | Collection |  |  |  | Lưu trữ các cấu trúc giao diện (Layouts/Templates) để định nghĩa cách hiển thị cho các Danh mục hoặc Bài viết cụ thể. |
| pages | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian. |
| pages | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định Page này thuộc về khách hàng nào (SaaS Isolation). |
| pages | code | VARCHAR(50) | NO |  | UNIQUE(tenant\_id, code) | Mã định danh dùng trong code Frontend (VD: news-grid-v1, landing-summer). |
| pages | name | TEXT | NO |  | CHECK (LENGTH(name) > 0) | Tên gợi nhớ của trang (VD: "Trang chủ Tin tức", "Layout Tuyển dụng"). |
| pages | type | VARCHAR(20) | NO | CATEGORY' | CHECK (type IN ('HOME', 'CATEGORY', 'DETAIL', 'LANDING')) | Phân loại trang: Trang chủ, Danh sách, Chi tiết bài viết, hay Landing page rời. |
| pages | layout\_config | JSONB | NO | {}' |  | Quan trọng: Chứa cấu hình kéo thả, danh sách components, slots, màu sắc (Schema-less). |
| pages | supported\_types | TEXT[] | NO | {}' |  | Danh sách các loại bài viết (article\_type) mà Page này hỗ trợ hiển thị (VD: ['NEWS', 'BLOG']). |
| pages | is\_system | BOOLEAN | NO | FALSE |  | TRUE: Page mẫu của hệ thống, Tenant không được xóa. FALSE: Page do Tenant tự tạo. |
| pages | is\_active | BOOLEAN | NO | TRUE |  | Trạng thái sử dụng. |
| pages | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo (UTC). |
| pages | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| pages | version | BIGINT | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking để tránh xung đột khi nhiều Admin cùng sửa layout. |
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
| reserved\_slugs | YSQL | Collection |  |  |  | Lưu các keyword không được dùng để đặt cho slug |
| reserved\_slugs | YSQL | Collection | NO |  | PRIMARY KEY | Định danh duy nhất bản ghi (Sử dụng UUID v7). [Source 26, 1236] |
| reserved\_slugs | YSQL | Collection | NO |  | UNIQUE, CHECK (slug \~ '^[a-z0-9-]+$') | Từ khóa bị cấm (Lưu chữ thường, không dấu). Là đối tượng chính cần kiểm tra. [Source 5, 2013] |
| reserved\_slugs | YSQL | Collection | NO | SYSTEM' | CHECK (type IN ('SYSTEM', 'BUSINESS', 'OFFENSIVE', 'FUTURE')) | Phân loại lý do cấm: Hệ thống, Nghiệp vụ, Nhạy cảm, hoặc Dành cho tương lai. |
| reserved\_slugs | YSQL | Collection | NO | EXACT' | CHECK (match\_type IN ('EXACT', 'PREFIX', 'REGEX')) | Cách thức so khớp: Chính xác (admin), Tiền tố (api-\*), hoặc Biểu thức chính quy. |
| reserved\_slugs | YSQL | Collection | NO | {}' |  | Snapshot ngữ cảnh: Lưu trữ danh sách các tài nguyên bị ảnh hưởng hoặc metadata liên quan tại thời điểm cấm (VD: routes hệ thống đang dùng keyword này). |
| reserved\_slugs | YSQL | Collection | YES | NULL |  | Thông báo lỗi hiển thị cho user (VD: "Từ khóa này dành riêng cho hệ thống"). |
| reserved\_slugs | YSQL | Collection | NO | TRUE |  | Trạng thái hiệu lực của từ khóa cấm. |
| reserved\_slugs | YSQL | Collection | NO | now() |  | Thời điểm thêm vào danh sách đen (UTC). [Source 40, 1143] |
| reserved\_slugs | YSQL | Collection | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| reserved\_slugs | YSQL | Collection | NO | 1 | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè. [Source 64] |
| routing\_slugs | YSQL | Collection |  |  |  | Trung tâm ánh xạ giữa các đường dẫn thân thiện (SEO-friendly URLs) và các thực thể dữ liệu thực tế (Bài viết, Sản phẩm, Danh mục) trong hệ thống |
| routing\_slugs | \_id | UUID | NO |  | PRIMARY KEY | Định danh duy nhất của bản ghi định tuyến. Sử dụng UUID v7 để tối ưu hóa sắp xếp thời gian và hiệu năng Sharding [Source 26, 27]. |
| routing\_slugs | tenant\_id | UUID | NO |  | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định slug này thuộc về website của khách hàng nào (SaaS Isolation). Là khóa phân vùng (Partition Key) quan trọng [Source 156, 456]. |
| routing\_slugs | slug | VARCHAR(255) | NO |  | CHECK (slug \~ '^[a-z0-9-]+$') | Đường dẫn URL (VD: ao-thun-nam). Chỉ chứa chữ thường, số và gạch ngang. Phải là duy nhất trong một Tenant [Source 97]. |
| routing\_slugs | entity\_type | VARCHAR(50) | NO |  | CHECK (length > 0) | Loại đối tượng đích (VD: PRODUCT, ARTICLE, CATEGORY, LANDING\_PAGE). Hỗ trợ mô hình đa hình (Polymorphic) [Source 2013]. |
| routing\_slugs | entity\_id | UUID | NO |  |  | ID của đối tượng thực tế (Primary Key của bảng Products/Articles...). |
| routing\_slugs | is\_canonical | BOOLEAN | NO | TRUE |  | TRUE: Đây là đường dẫn chính thức (Canonical URL). FALSE: Đây là đường dẫn cũ hoặc phụ (Alias/Redirect 301). |
| routing\_slugs | redirect\_to | VARCHAR(255) | YES | NULL |  | Nếu is\_canonical = FALSE, trường này chứa slug mới để hệ thống thực hiện Redirect 301. |
| routing\_slugs | items\_snapshot | JSONB | NO | {}' |  | Snapshot dữ liệu: Lưu trữ thông tin tóm tắt của đối tượng (Tiêu đề, Ảnh thumbnail, SEO Meta) tại thời điểm tạo slug. Giúp Frontend render Link Preview hoặc Breadcrumb mà không cần JOIN vào bảng gốc [Source 23, 1459]. |
| routing\_slugs | created\_at | TIMESTAMPTZ | NO | now() |  | Thời điểm tạo đường dẫn (UTC) [Source 12, 20]. |
| routing\_slugs | updated\_at | TIMESTAMPTZ | NO | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
