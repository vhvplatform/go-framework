|     | A   | B   | C   | D   | E   | F   | G   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1   | Bảng | Tên trường (Field) | Kiểu dữ liệu | Null? | Mặc định (Default) | Ràng buộc (Constraints) & Logic Kiểm tra | Mô tả |
|     |     |     |     |     |     |     |     |
| 2   | CORE & IDENTITY (HẠ TẦNG & ĐỊNH DANH) |     | Package |     |     |     |     |
| 3   | Nhóm Định danh và Tổ chức Cốt lõi (Core Foundation) |     | Package |     |     |     | Nhóm này quản lý danh tính con người và cấu trúc pháp nhân của khách hàng |
| 4   | tenants | YSQL | Collection |     |     |     | Lưu thông tin khách hàng, định danh (\_id, code), ràng buộc vùng (data\_region) và cấu hình gốc. |
| 5   | tenants | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 6   | tenants | code | VARCHAR(64) | NO  |     | UNIQUE, CHECK (code ~ '^\[a-z0-9-\]+$') | Mã định danh (Slug/Subdomain). Chỉ chứa chữ thường, số, gạch ngang. |
| 7   | tenants | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên hiển thị chính thức của công ty. |
| 8   | tenants | data\_region | VARCHAR(50) | NO  | ap-southeast-1' | CHECK (data\_region IN ('ap-southeast-1', 'us-east-1', 'eu-central-1')) | Vị trí vật lý lưu trữ dữ liệu (Geo-Partitioning) để tuân thủ pháp lý. |
| 9   | tenants | parent\_tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | ID của công ty mẹ hoặc đối tác phân phối cấp trên. |
| 10  | tenants | path | TEXT | YES |     | BTREE INDEX | Materialized Path (VD: /mẹ/con/) giúp truy vấn cây đối tác cực nhanh. |
| 11  | tenants | compliance\_level | VARCHAR(20) | NO  | STANDARD' | CHECK (compliance\_level IN ('STANDARD', 'GDPR', 'HIPAA', 'PCI-DSS')) | Mức độ tuân thủ bảo mật, quyết định quy trình xử lý dữ liệu. |
| 12  | tenants | tier | VARCHAR(50) | NO  | FREE' | CHECK (tier IN (  <br>'FREE', 'PRO', 'ENTERPRISE', -- Khách hàng cuối  <br>'PARTNER\_BASIC', 'PARTNER\_PREMIUM', 'PARTNER\_ELITE', -- Đối tác  <br>'PROVIDER' -- Chủ nền tảng  <br>)) | Cấp độ gói dịch vụ (VD: FREE, PRO, ENTERPRISE). |
| 13  | tenants | billing\_type | VARCHAR(20) | NO  | POSTPAID' | CHECK (billing\_type IN ('PREPAID', 'POSTPAID')) | Hình thức thanh toán: Trả trước hoặc trả sau. |
| 14  | tenants | timezone | VARCHAR(50) | NO  | UTC' |     | Múi giờ hành chính để tính toán thời hạn gói và báo cáo. |
| 15  | tenants | profile | JSONB | NO  | {}' |     | Thông tin thương hiệu và bộ nhận diện (Metadata hiển thị).  <br>1\. Thông tin thương hiệu và nhận diện (Branding)  <br>Đây là nhóm thông tin chính dùng để cá nhân hóa giao diện người dùng (UI/UX) cho từng khách hàng doanh nghiệp:  <br>• description: Mô tả ngắn gọn về hoạt động kinh doanh hoặc giới thiệu về công ty,. Thông tin này thường hiển thị trên trang hồ sơ công khai hoặc trang quản trị nội bộ.  <br>• logo\_url: Đường dẫn đến tệp ảnh logo của công ty,. Do các URL này có thể rất dài (đặc biệt khi sử dụng Presigned URL từ S3 hoặc các dịch vụ CDN), việc lưu trong JSONB giúp linh hoạt hơn so với các cột VARCHAR giới hạn,.  <br>• website\_url (hoặc website): Địa chỉ trang chủ chính thức của doanh nghiệp,.  <br>2\. Thông tin pháp lý và thuế (Tax & Legal)  <br>Nhóm này lưu trữ các dữ liệu cần thiết cho việc xuất hóa đơn hoặc xác minh danh tính doanh nghiệp mà không cần tạo quá nhiều cột rời rạc:  <br>• tax\_info: Một đối tượng lồng nhau (nested object) bao gồm:  <br>◦ tax\_code: Mã số thuế của doanh nghiệp,.  <br>◦ address: Địa chỉ pháp lý đăng ký trên giấy phép kinh doanh (khác với địa chỉ văn phòng thực tế có thể thay đổi),.  <br>3\. Liên kết mạng xã hội (Social Links)  <br>Trường profile cho phép lưu trữ không giới hạn các liên kết mạng xã hội tùy theo nhu cầu của từng Tenant:  <br>• socials (hoặc social\_links): Một đối tượng chứa các khóa như:  <br>◦ facebook: Link trang Fanpage.  <br>◦ linkedin: Link hồ sơ doanh nghiệp trên LinkedIn.  <br>◦ twitter, tiktok, hoặc các nền tảng khác phát sinh sau này,.  <br>4\. Các thuộc tính tùy biến khác  <br>Vì tính chất schema-less của JSONB, trường profile có thể mở rộng thêm các thuộc tính mà không cần sửa đổi cấu trúc bảng (ALTER TABLE),:  <br>• industry: Ngành nghề kinh doanh cụ thể.  <br>• founded\_year: Năm thành lập.  <br>• contact\_person: Thông tin người liên hệ bổ sung (nếu không nằm trong các bảng chuyên biệt). |
| 16  | tenants | settings | JSONB | NO  | {}' |     | Cấu hình vận hành và chính sách bảo mật (Metadata logic).  <br>1\. Chính sách bảo mật (Security Policies)  <br>Đây là nhóm thuộc tính quan trọng nhất, giúp thực thi các tiêu chuẩn an ninh khắt khe của doanh nghiệp.  <br>• password\_policy: Đối tượng cấu hình mật khẩu, bao gồm:  <br>◦ min\_length: Độ dài tối thiểu của mật khẩu (thường >= 8).  <br>◦ require\_special\_char: Bắt buộc mật khẩu có ký tự đặc biệt.  <br>◦ expiry\_days: Số ngày mật khẩu hết hạn (0 là không bao giờ).  <br>◦ history\_limit: Số lượng mật khẩu cũ không được phép trùng lại.  <br>• mfa\_enforced: Cờ BOOLEAN bắt buộc tất cả người dùng thuộc Tenant này phải bật xác thực 2 yếu tố (MFA).  <br>• ip\_whitelist (hoặc allowed\_ip\_ranges): Mảng chứa các dải địa chỉ IP (CIDR) được phép truy cập vào hệ thống.  <br>• session\_policy: Cấu hình phiên làm việc:  <br>◦ timeout\_minutes: Thời gian tự động đăng xuất khi không hoạt động.  <br>◦ max\_login\_attempts: Số lần thử sai tối đa trước khi khóa tài khoản.  <br>2\. Cấu hình vận hành và Hạ tầng (Operational & Infrastructure)  <br>Nhóm này quy định cách hệ thống xử lý dữ liệu và định tuyến cho Tenant.  <br>• compliance: Mức độ tuân thủ bảo mật (ví dụ: GDPR, HIPAA, PCI-DSS), quyết định quy trình xóa vĩnh viễn hoặc lưu vết dữ liệu.  <br>• data\_residency: Quy định vùng địa lý lưu trữ dữ liệu để đảm bảo tuân thủ luật pháp quốc gia (ví dụ: ap-southeast-1).  <br>• rate\_limiting: Hạn ngạch gọi API cho từng Tenant để chống DDoS nội bộ và quá tải hệ thống.  <br>◦ requests\_per\_minute: Số lượng request tối đa trong một phút.  <br>◦ burst\_size: Số lượng request tối đa cho phép bùng phát trong thời gian ngắn.  <br>3\. Chính sách lưu trữ và Phê duyệt (Governance)  <br>Dành cho các yêu cầu quản trị chuyên sâu của khách hàng Enterprise.  <br>• archival\_policy: Quy định thời gian dữ liệu được giữ lại trong DB trước khi đẩy vào kho lưu trữ lạnh (S3).  <br>◦ audit\_log\_retention\_days: Số ngày lưu giữ nhật ký truy vết.  <br>◦ invoice\_retention\_days: Số ngày lưu giữ hóa đơn trong hệ thống.  <br>• approval\_required: Cờ bắt buộc các hành động nhạy cảm (như xóa dữ liệu, xuất file) phải qua quy trình phê duyệt (Maker-Checker). |
| 17  | tenants | status | VARCHAR(20) | NO  | TRIAL' | CHECK (status IN ('TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED')) | Trạng thái vòng đời của tenant. |
| 18  | tenants | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC). |
| 19  | tenants | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| 20  | tenants | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Cờ xóa mềm (Soft Delete) phục vụ truy vết và khôi phục. |
| 21  | tenants | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè dữ liệu đồng thời. |
| 22  | tenants | active\_apps | TEXT\[\] | YES | NULL |     | Cache danh sách App. Mảng chứa mã các ứng dụng mà tenant có quyền truy cập để API Gateway kiểm tra nhanh. |
| 23  | tenants | metadata | JSONB | NO  | {}' |     | Lưu trữ linh hoạt các thông tin profile như Logo, Website, Tax Code hoặc các thuộc tính tùy chỉnh. |
| 24  | users | YSQL | Collection |     |     |     | Lưu trữ thông tin định danh toàn cục của một con người thực (Email, Password Hash, Avatar). Đây là bảng duy nhất chứa thông tin đăng nhập trên toàn sàn. |
| 25  | users | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất toàn cục. Sử dụng UUID v7 để sắp xếp theo thời gian, giúp tăng tốc độ chèn và truy vấn. |
| 26  | users | email | VARCHAR(255) | NO  |     | UNIQUE, CHECK (email ~\* '^\[A-Za-z0-9.\_+%-\]+@\[A-Za-z0-9.-\]+\[.\]\[A-Za-z\]+$') | Email đăng nhập chính. Phải là duy nhất trên toàn sàn và đúng định dạng. |
| 27  | users | password\_hash | TEXT | YES | NULL |     | Chuỗi băm mật khẩu (Argon2/Bcrypt). Để trống nếu người dùng chỉ sử dụng SSO hoặc Social Login. |
| 28  | users | full\_name | TEXT | NO  |     | CHECK (LENGTH(full\_name) > 0) | Tên hiển thị mặc định của người dùng. |
| 29  | users | phone\_number | VARCHAR(20) | YES | NULL | UNIQUE | Số điện thoại cá nhân dùng cho xác thực 2 lớp (MFA) hoặc khôi phục tài khoản. |
| 30  | users | status | VARCHAR(20) | NO  | ACTIVE' | CHECK (status IN ('ACTIVE', 'BANNED', 'DISABLED', 'PENDING')) | Trạng thái tài khoản trên toàn hệ thống. |
| 31  | users | is\_support\_staff | BOOLEAN | NO  | FALSE |     | Đánh dấu nhân viên hỗ trợ của nhà cung cấp SaaS để kích hoạt tính năng Impersonation (giả mạo). |
| 32  | users | mfa\_enabled | BOOLEAN | NO  | FALSE |     | Trạng thái bật/tắt xác thực đa yếu tố. |
| 33  | users | is\_verified | BOOLEAN | NO  | FALSE |     | Đánh dấu email đã được xác thực chính chủ hay chưa. |
| 34  | users | locale | VARCHAR(10) | NO  | vi-VN' |     | Ngôn ngữ và định dạng hiển thị ưa thích của người dùng. |
| 35  | users | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo tài khoản (UTC). |
| 36  | users | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật thông tin gần nhất. |
| 37  | users | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Soft Delete: Nếu khác NULL, tài khoản coi như đã bị xóa nhưng vẫn giữ dữ liệu cho mục đích đối soát (Audit). |
| 38  | tenant\_members | YSQL | Collection |     |     |     | Bảng liên kết người dùng với tổ chức. Nó lưu hồ sơ nhân viên, mã nhân viên, chức danh và trạng thái làm việc tại một công ty cụ thể. |
| 39  | tenant\_members | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tối ưu sắp xếp và chèn dữ liệu. |
| 40  | tenant\_members | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) | Xác định thành viên thuộc tổ chức nào. Là Sharding Key quan trọng. |
| 41  | tenant\_members | user\_id | UUID | NO  |     | REFERENCES users(\_id) | Liên kết với danh tính người dùng toàn cục. |
| 42  | tenant\_members | display\_name | VARCHAR(255) | YES |     |     | Tên hiển thị riêng trong tổ chức (VD: "Anh An IT"). |
| 43  | tenant\_members | status | VARCHAR(20) | NO  | INVITED' | CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'RESIGNED')) | Trạng thái hoạt động của thành viên trong tổ chức này. |
| 44  | tenant\_members | custom\_data | JSONB | NO  | {}' |     | Lưu trữ linh hoạt các trường động (Mã NV, chức danh, size áo...). |
| 45  | tenant\_members | joined\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm chính thức gia nhập tổ chức. |
| 46  | tenant\_members | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi hồ sơ. |
| 47  | tenant\_members | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật hồ sơ gần nhất. |
| 48  | tenant\_members | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Soft Delete. Thời điểm xóa thành viên khỏi tổ chức. |
| 49  | tenant\_members | created\_by | UUID | YES |     |     | ID người thực hiện tạo hồ sơ (Admin/System). |
| 50  | tenant\_members | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking. Chống ghi đè dữ liệu khi nhiều Admin cùng sửa. |
| 51  | Nhóm Cơ cấu và Nhóm (Organization & Structure) |     | Package |     |     |     | Giúp phản ánh cấu trúc thực tế của doanh nghiệp |
| 52  | departments | YSQL | Collection |     |     |     | Quản lý cây phòng ban theo phân cấp (Hierarchy) sử dụng phương pháp Materialized Path để truy vấn nhanh |
| 53  | departments | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (UUID v7). Tối ưu hóa việc sắp xếp theo thời gian và tránh Hotspot,. |
| 54  | departments | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) | Xác định phòng ban thuộc tổ chức nào (Sharding Key quan trọng),. |
| 55  | departments | parent\_id | UUID | YES | NULL | REFERENCES departments(\_id) | ID của phòng ban cha. Dùng để xây dựng quan hệ phân cấp,. |
| 56  | departments | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên phòng ban (VD: Khối Công nghệ, Phòng Nhân sự). |
| 57  | departments | code | VARCHAR(50) | YES | NULL |     | Mã phòng ban dùng để đồng bộ với hệ thống ERP bên ngoài. |
| 58  | departments | type | VARCHAR(20) | NO  | TEAM' | CHECK (type IN ('DIVISION', 'DEPARTMENT', 'TEAM')) | Phân loại cấp độ tổ chức,. |
| 59  | departments | head\_member\_id | UUID | YES | NULL | REFERENCES tenant\_members(\_id) | Trưởng phòng (Administrative Head). Link tới hồ sơ thành viên,. |
| 60  | departments | path | TEXT | YES |     |     | Materialized Path (VD: /root/dept\_a/team\_b/). Giúp truy vấn toàn bộ cây con cực nhanh,. |
| 61  | departments | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC),. |
| 62  | departments | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng,. |
| 63  | departments | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Soft Delete. Nếu khác NULL, phòng ban coi như đã bị giải thể,. |
| 64  | departments | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking. Ngăn chặn việc cập nhật dữ liệu đồng thời bị xung đột,. |
| 65  | department\_members | YSQL | Collection |     |     |     | Phân bổ nhân sự vào các phòng ban (quan hệ N-N) |
| 66  | department\_members | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" trong hệ thống phân tán. |
| 67  | department\_members | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) | Xác định bản ghi thuộc tổ chức nào (Sharding Key quan trọng). |
| 68  | department\_members | department\_id | UUID | NO  |     | REFERENCES departments(\_id) | Liên kết tới phòng ban cụ thể. |
| 69  | department\_members | member\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) | Liên kết tới hồ sơ nhân sự trong Tenant. |
| 70  | department\_members | is\_primary | BOOLEAN | NO  | FALSE |     | Đánh dấu đây có phải là phòng ban chính của nhân sự này không (dùng để tính headcount). |
| 71  | department\_members | role\_in\_dept | VARCHAR(100) | YES | NULL |     | Vai trò cụ thể trong phòng ban này (VD: Thư ký, Điều phối viên). |
| 72  | department\_members | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm nhân sự được gán vào phòng ban (UTC). |
| 73  | department\_members | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật hồ sơ gần nhất. |
| 74  | user\_groups | YSQL | Collection |     |     |     | Quản lý các nhóm làm việc ngang hàng, dự án hoặc squad. Có thể thiết lập nhóm tĩnh hoặc nhóm động (Dynamic Groups) theo quy tắc |
| 75  | user\_groups | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (khuyến nghị dùng UUID v7 để tối ưu sắp xếp theo thời gian),. |
| 76  | user\_groups | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định nhóm thuộc tổ chức nào (Sharding Key quan trọng),. |
| 77  | user\_groups | parent\_id | UUID | YES | NULL | REFERENCES user\_groups(\_id) | ID của nhóm cha, dùng để xây dựng cấu trúc phân cấp lồng nhau,. |
| 78  | user\_groups | name | VARCHAR(100) | NO  |     | CHECK (LENGTH(name) > 0) | Tên nhóm (VD: "Squad Mobile", "Phòng IT"). |
| 79  | user\_groups | code | VARCHAR(50) | YES | NULL |     | Mã định danh duy nhất trong một tenant (VD: GRP\_DEV\_01). |
| 80  | user\_groups | type | VARCHAR(20) | NO  | CUSTOM' | CHECK (type IN ('ORG\_UNIT', 'PROJECT', 'PERMISSION', 'CUSTOM')) | Phân loại: Phòng ban, Dự án, Nhóm quyền hoặc nhóm tùy chỉnh. |
| 81  | user\_groups | dynamic\_rules | JSONB | YES | NULL |     | Quy tắc để tự động thêm thành viên (VD: {"dept": "IT", "loc": "HN"}),. |
| 82  | user\_groups | path | TEXT | YES | NULL |     | Materialized Path (VD: /root-id/child-id/) giúp truy vấn cây nhóm cực nhanh,. |
| 83  | user\_groups | description | TEXT | YES | NULL |     | Mô tả chi tiết về mục đích của nhóm. |
| 84  | user\_groups | owner\_member\_id | UUID | YES | NULL | REFERENCES tenant\_members(\_id) | ID người quản trị/trưởng nhóm,. |
| 85  | user\_groups | created\_at | TIMESTAMPTZ | NO  | NOW() |     | Thời điểm tạo nhóm (UTC),. |
| 86  | user\_groups | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời,. |
| 87  | group\_members | YSQL | Collection |     |     |     | Danh sách thành viên trong các nhóm tĩnh |
| 88  | group\_members | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp sắp xếp theo thời gian. |
| 89  | group\_members | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định thành viên nhóm thuộc tổ chức nào (Sharding Key). |
| 90  | group\_members | group\_id | UUID | NO  |     | REFERENCES user\_groups(\_id) ON DELETE CASCADE | Liên kết với nhóm (Squad, Dự án, Phòng ban). |
| 91  | group\_members | member\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) ON DELETE CASCADE | Liên kết với hồ sơ nhân sự cụ thể trong Tenant. |
| 92  | group\_members | role\_in\_group | VARCHAR(20) | NO  | MEMBER' | CHECK (role\_in\_group IN ('LEADER', 'MEMBER', 'SECRETARY')) | Vai trò cụ thể của thành viên trong nhóm này. |
| 93  | group\_members | joined\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm thành viên gia nhập nhóm. |
| 94  | group\_members | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC). |
| 95  | group\_members | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking: Ngăn chặn ghi đè dữ liệu khi nhiều Admin cùng thao tác. |
| 96  | locations | YSQL | Collection |     |     |     | Quản lý các địa điểm vật lý, văn phòng hoặc chi nhánh của Tenant |
| 97  | locations | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (sử dụng UUID v7 để tối ưu sắp xếp theo thời gian),. |
| 98  | locations | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định chi nhánh thuộc tổ chức nào (Sharding Key),. |
| 99  | locations | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên văn phòng/chi nhánh (VD: FPT Tower Hà Nội). |
| 100 | locations | code | VARCHAR(50) | YES | NULL |     | Mã địa điểm dùng để đồng bộ với thiết kế HRM hoặc máy chấm công,. |
| 101 | locations | address | JSONB | NO  | {}' |     | Lưu chi tiết địa chỉ: số nhà, phường, quận, quốc gia. |
| 102 | locations | coordinates | POINT | YES | NULL |     | Tọa độ GPS (Lat/Long) để xác thực vị trí chấm công. |
| 103 | locations | radius\_meters | INT | YES | NULL | CHECK (radius\_meters > 0) | Bán kính cho phép chấm công xung quanh tọa độ (đơn vị: mét). |
| 104 | locations | timezone | VARCHAR(50) | NO  | Asia/Ho\_Chi\_Minh' |     | Múi giờ tại địa phương, quan trọng để tính toán ca làm việc. |
| 105 | locations | is\_headquarter | BOOLEAN | NO  | FALSE |     | Đánh dấu nếu đây là trụ sở chính của công ty. |
| 106 | locations | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC),. |
| 107 | locations | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng,. |
| 108 | locations | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking ngăn chặn xung đột khi nhiều người cùng sửa cấu hình. |
| 109 | Nhóm Xác thực và Bảo mật (Authentication & Security) |     | Package |     |     |     | Đáp ứng các tiêu chuẩn bảo mật hiện đại như MFA và Passwordless |
| 110 | user\_linked\_identities | YSQL | Collection |     |     |     | Quản lý đa phương thức đăng nhập (Password, Google, GitHub, Microsoft) liên kết với một tài khoản người dùng. |
| 111 | user\_linked\_identities | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sắp xếp theo thời gian và sharding. |
| 112 | user\_linked\_identities | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến hồ sơ người dùng gốc trong bảng users. |
| 113 | user\_linked\_identities | provider | VARCHAR(20) | NO  |     | CHECK (provider IN ('LOCAL', 'GOOGLE', 'GITHUB', 'MICROSOFT', 'APPLE', 'PASSKEY')) | Nguồn định danh (LOCAL là mật khẩu truyền thống, còn lại là OAuth/SSO). |
| 114 | user\_linked\_identities | provider\_id | VARCHAR(255) | NO  |     | UNIQUE(provider, provider\_id) | ID định danh tại nguồn (Email đối với LOCAL, Subject ID đối với OAuth). |
| 115 | user\_linked\_identities | password\_hash | TEXT | YES | NULL |     | Lưu chuỗi băm mật khẩu (chỉ sử dụng khi provider = 'LOCAL'). |
| 116 | user\_linked\_identities | data | JSONB | NO  | {}' |     | Lưu trữ linh hoạt metadata như: access\_token, refresh\_token, profile\_url từ nhà cung cấp. |
| 117 | user\_linked\_identities | last\_login\_at | TIMESTAMPTZ | YES | NULL |     | Ghi nhận thời điểm cuối cùng đăng nhập bằng phương thức này. |
| 118 | user\_linked\_identities | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm liên kết phương thức đăng nhập này vào tài khoản. |
| 119 | user\_sessions | YSQL | Collection |     |     |     | Quản lý phiên làm việc thực tế, thiết bị, IP và hỗ trợ cơ chế xoay vòng token (Rotation). |
| 120 | user\_sessions | \_id | UUID | NO  |     | PRIMARY KEY | Định danh phiên (Session ID). Sử dụng UUID v7 để tối ưu sharding và sắp xếp theo thời gian. |
| 121 | user\_sessions | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) | Xác định phiên thuộc tổ chức nào (SaaS Isolation). |
| 122 | user\_sessions | user\_id | UUID | NO  |     | REFERENCES users(\_id) | Liên kết tới người dùng sở hữu phiên. |
| 123 | user\_sessions | family\_id | UUID | NO  |     |     | Định danh chuỗi token (Family). Dùng để thu hồi toàn bộ chuỗi nếu phát hiện token bị trộm. |
| 124 | user\_sessions | refresh\_token\_hash | VARCHAR(255) | YES | NULL |     | Lưu chuỗi băm của Refresh Token hiện tại để thực hiện cơ chế xoay vòng. |
| 125 | user\_sessions | rotation\_counter | INT | NO  | 0   | CHECK (rotation\_counter >= 0) | Số lần xoay vòng token. Nếu phát hiện dùng lại counter thấp, hệ thống sẽ hủy cả family. |
| 126 | user\_sessions | ip\_address | INET | YES |     |     | Địa chỉ IP của thiết bị đăng nhập. |
| 127 | user\_sessions | user\_agent | TEXT | YES |     |     | Thông tin trình duyệt và hệ điều hành (Fingerprint). |
| 128 | user\_sessions | device\_type | VARCHAR(20) | YES |     |     | Phân loại thiết bị: MOBILE, DESKTOP, TABLET. |
| 129 | user\_sessions | location\_city | VARCHAR(100) | YES |     |     | Thành phố đăng nhập (GeoIP). |
| 130 | user\_sessions | is\_revoked | BOOLEAN | NO  | FALSE |     | Trạng thái bị thu hồi. Nếu TRUE, phiên không còn hiệu lực (dùng cho tính năng "Đăng xuất từ xa"). |
| 131 | user\_sessions | expires\_at | TIMESTAMPTZ | NO  |     |     | Thời điểm phiên hết hạn hoàn toàn. |
| 132 | user\_sessions | last\_active\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cuối cùng phiên có hoạt động. |
| 133 | user\_sessions | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm bắt đầu phiên đăng nhập. |
| 134 | user\_mfa\_methods | YSQL | Collection |     |     |     | Lưu trữ các phương thức xác thực đa yếu tố (TOTP, SMS, Email). |
| 135 | user\_mfa\_methods | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (Sử dụng UUID v7 để tối ưu sharding và sắp xếp theo thời gian). |
| 136 | user\_mfa\_methods | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến người dùng sở hữu phương thức MFA này. |
| 137 | user\_mfa\_methods | type | VARCHAR(20) | NO  |     | CHECK (type IN ('TOTP', 'SMS', 'EMAIL', 'HARDWARE')) | Loại xác thực: TOTP (App), SMS, Email hoặc khóa cứng. |
| 138 | user\_mfa\_methods | name | VARCHAR(50) | YES | NULL |     | Tên gợi nhớ cho thiết bị (VD: "iPhone 15 của An"). |
| 139 | user\_mfa\_methods | encrypted\_secret | TEXT | NO  |     |     | Chuỗi bí mật (Secret Key) đã được mã hóa trước khi lưu để đảm bảo an toàn. |
| 140 | user\_mfa\_methods | is\_default | BOOLEAN | NO  | FALSE |     | Đánh dấu phương thức ưu tiên khi đăng nhập. |
| 141 | user\_mfa\_methods | last\_used\_at | TIMESTAMPTZ | YES | NULL |     | Ghi lại thời điểm cuối cùng phương thức này được sử dụng. |
| 142 | user\_mfa\_methods | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm đăng ký phương thức MFA này. |
| 143 | user\_webauthn\_credentials | YSQL | Collection |     |     |     | Hỗ trợ đăng nhập bằng vân tay, FaceID hoặc khóa vật lý (Passkeys/FIDO2). |
| 144 | user\_webauthn\_credentials | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (Sử dụng UUID v7 để tối ưu sắp xếp theo thời gian và phân tán dữ liệu),. |
| 145 | user\_webauthn\_credentials | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến tài khoản người dùng gốc. |
| 146 | user\_webauthn\_credentials | name | VARCHAR(100) | YES | NULL |     | Tên gợi nhớ cho thiết bị (VD: "MacBook TouchID", "YubiKey 5C"). |
| 147 | user\_webauthn\_credentials | credential\_id | TEXT | NO  |     | UNIQUE | ID định danh duy nhất của thiết bị WebAuthn trả về, dùng để nhận diện thiết bị khi đăng nhập,. |
| 148 | user\_webauthn\_credentials | public\_key | TEXT | NO  |     |     | Khóa công khai dùng để xác thực chữ ký số từ thiết bị trong mỗi lần đăng nhập,. |
| 149 | user\_webauthn\_credentials | sign\_count | INT | NO  | 0   | CHECK (sign\_count >= 0) | Bộ đếm số lần sử dụng nhằm chống lại các cuộc tấn công phát lại (Replay Attack),. |
| 150 | user\_webauthn\_credentials | transports | TEXT\[\] | YES | NULL |     | Mảng lưu các phương thức kết nối được hỗ trợ (VD: {'usb', 'nfc', 'ble', 'internal'}). |
| 151 | user\_webauthn\_credentials | last\_used\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm gần nhất thiết bị này được sử dụng để đăng nhập. |
| 152 | user\_webauthn\_credentials | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm đăng ký thiết bị vào hệ thống (UTC),. |
| 153 | user\_backup\_codes | YSQL | Collection |     |     |     | Mã khôi phục khi người dùng mất thiết bị MFA. |
| 154 | user\_backup\_codes | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" và tối ưu hóa việc phân tán dữ liệu,. |
| 155 | user\_backup\_codes | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết đến tài khoản người dùng gốc trong hệ thống định danh toàn cầu,. |
| 156 | user\_backup\_codes | code\_hash | TEXT | NO  |     |     | Chuỗi băm của mã dự phòng (tương tự mật khẩu, tuyệt đối không lưu dạng rõ),. |
| 157 | user\_backup\_codes | is\_used | BOOLEAN | NO  | FALSE |     | Trạng thái mã đã được sử dụng hay chưa. |
| 158 | user\_backup\_codes | used\_at | TIMESTAMPTZ | YES | NULL |     | Ghi lại thời điểm chính xác mã này được sử dụng để khôi phục tài khoản. |
| 159 | user\_backup\_codes | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo mã (luôn lưu theo giờ UTC),. |
| 160 | tenant\_sso\_configs | YSQL | Collection |     |     |     | Cấu hình đăng nhập doanh nghiệp (SAML/OIDC) để tích hợp với Azure AD, Okta. |
| 161 | tenant\_sso\_configs | tenant\_id | UUID | NO  |     | PRIMARY KEY, REFERENCES tenants(\_id) ON DELETE CASCADE | Định danh Tenant. Mỗi tổ chức thường chỉ có một cấu hình SSO chính,. Sử dụng UUID v7 để tối ưu hiệu năng. |
| 162 | tenant\_sso\_configs | provider\_type | VARCHAR(20) | NO  |     | CHECK (provider\_type IN ('AZURE\_AD', 'OKTA', 'GOOGLE', 'SAML', 'OIDC')) | Loại nhà cung cấp định danh (IdP),. |
| 163 | tenant\_sso\_configs | entry\_point\_url | TEXT | NO  |     |     | URL đăng nhập của nhà cung cấp định danh bên ngoài,. |
| 164 | tenant\_sso\_configs | issuer\_id | TEXT | YES | NULL |     | Định danh thực thể (Entity ID/Issuer) của IdP. |
| 165 | tenant\_sso\_configs | cert\_public\_key | TEXT | YES | NULL |     | Chứng chỉ PEM dùng để xác thực chữ ký số từ IdP (SAML),. |
| 166 | tenant\_sso\_configs | client\_id | VARCHAR(255) | YES | NULL |     | Client ID dùng cho phương thức OIDC. |
| 167 | tenant\_sso\_configs | client\_secret\_enc | TEXT | YES | NULL |     | Client Secret đã mã hóa (chỉ dùng cho OIDC). |
| 168 | tenant\_sso\_configs | attribute\_mapping | JSONB | NO  | {}' |     | Ánh xạ các trường dữ liệu (VD: map 'mail' của IdP sang 'email' của hệ thống),. |
| 169 | tenant\_sso\_configs | is\_enforced | BOOLEAN | NO  | FALSE |     | Nếu TRUE, bắt buộc nhân viên phải đăng nhập qua SSO, cấm dùng mật khẩu thông thường,. |
| 170 | tenant\_sso\_configs | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo cấu hình (UTC),. |
| 171 | tenant\_sso\_configs | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| 172 | tenant\_sso\_configs | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking để chống ghi đè dữ liệu đồng thời. |
| 173 | auth\_verification\_codes | YSQL | Collection |     |     |     | Mã OTP hoặc Magic Link ngắn hạn để xác thực email hoặc đổi mật khẩu. |
| 174 | auth\_verification\_codes | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding. |
| 175 | auth\_verification\_codes | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định mã thuộc tổ chức nào (SaaS Isolation). |
| 176 | auth\_verification\_codes | identifier | VARCHAR(255) | NO  |     |     | Email hoặc số điện thoại nhận mã xác thực. |
| 177 | auth\_verification\_codes | type | VARCHAR(30) | NO  |     | CHECK (type IN ('EMAIL\_VERIFICATION', 'PASSWORD\_RESET', 'LOGIN\_OTP', 'MAGIC\_LINK')) | Phân loại mục đích của mã xác thực. |
| 178 | auth\_verification\_codes | code\_hash | TEXT | NO  |     |     | Chuỗi băm (Hash) của mã bí mật để đảm bảo an toàn, không lưu dạng rõ. |
| 179 | auth\_verification\_codes | expires\_at | TIMESTAMPTZ | NO  |     |     | Thời điểm mã hết hạn (thường từ 5-15 phút). |
| 180 | auth\_verification\_codes | attempt\_count | INT | NO  | 0   | CHECK (attempt\_count <= 5) | Bộ đếm số lần nhập sai để chống tấn công Brute-force. |
| 181 | auth\_verification\_codes | metadata | JSONB | YES | {}' |     | Lưu ngữ cảnh bổ sung như redirect\_url hoặc device\_info. |
| 182 | auth\_verification\_codes | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo mã (UTC). |
| 183 | personal\_access\_tokens | YSQL | Collection |     |     |     | Token dành cho lập trình viên hoặc scripts tích hợp hệ thống. |
| 184 | personal\_access\_tokens | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất. Sử dụng UUID v7 để tối ưu sắp xếp theo thời gian và tránh "hotspot" trong DB phân tán. |
| 185 | personal\_access\_tokens | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định token thuộc tổ chức nào để đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| 186 | personal\_access\_tokens | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Người dùng sở hữu và tạo ra token này. |
| 187 | personal\_access\_tokens | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên gợi nhớ của token (Ví dụ: "Script Sync Excel", "Jenkins CI/CD"). |
| 188 | personal\_access\_tokens | token\_prefix | VARCHAR(10) | NO  |     |     | Chuỗi tiền tố (Ví dụ: pat\_live\_) để người dùng nhận diện token mà không cần lộ toàn bộ. |
| 189 | personal\_access\_tokens | token\_hash | TEXT | NO  |     | UNIQUE | Bản băm của token (SHA-256). Tuyệt đối không lưu token gốc. |
| 190 | personal\_access\_tokens | scopes | TEXT\[\] | NO  |     |     | Mảng các quyền hạn (Ví dụ: \['user:read', 'report:export'\]) giới hạn phạm vi truy cập. |
| 191 | personal\_access\_tokens | last\_used\_at | TIMESTAMPTZ | YES | NULL |     | Ghi lại thời điểm gần nhất token này được sử dụng để gọi API. |
| 192 | personal\_access\_tokens | expires\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm hết hạn. Nếu NULL nghĩa là token vĩnh viễn (khuyến nghị có hạn). |
| 193 | personal\_access\_tokens | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái kích hoạt. Cho phép người dùng vô hiệu hóa nhanh token mà không cần xóa. |
| 194 | personal\_access\_tokens | created\_at | TIMESTAMPTZ | NO  | NOW() |     | Thời điểm tạo mã token (luôn lưu theo giờ UTC). |
| 195 | personal\_access\_tokens | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Sử dụng cho cơ chế Optimistic Locking để tránh ghi đè dữ liệu đồng thời. |
| 196 | auth\_logs | ClickHouse | Collection |     |     |     |     |
| 197 | auth\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 198 | auth\_logs | tenant\_id | UUID | NO  |     |     | Định danh tổ chức sở hữu log này (Dùng để lọc dữ liệu),. |
| 199 | auth\_logs | user\_id | Nullable(UUID) | YES | NULL |     | ID người dùng nếu đăng nhập thành công hoặc email tồn tại. |
| 200 | auth\_logs | impersonator\_id | Nullable(UUID) | YES | NULL |     | ID nhân viên Support nếu đang sử dụng tính năng "Impersonation",. |
| 201 | auth\_logs | email\_attempted | String | NO  |     |     | Email người dùng đã nhập vào khi thử đăng nhập. |
| 202 | auth\_logs | ip\_address | IPv6 | NO  |     |     | Địa chỉ IP truy cập (Lưu chuẩn IPv6 để bao quát cả IPv4). |
| 203 | auth\_logs | user\_agent | String | NO  |     |     | Thông tin trình duyệt và hệ điều hành (User Agent). |
| 204 | auth\_logs | is\_success | Bool | NO  |     |     | true nếu thành công, false nếu thất bại,. |
| 205 | auth\_logs | login\_method | Enum8(...) | NO  | PASSWORD' | PASSWORD, GOOGLE, SSO, MAGIC\_LINK | Phương thức xác thực được sử dụng,. |
| 206 | auth\_logs | failure\_reason | Enum8(...) | NO  | NONE' | NONE, WRONG\_PW, MFA\_FAIL, LOCKED | Lý do thất bại (nếu có) để phục vụ phân tích bảo mật. |
| 207 | auth\_logs | created\_at | DateTime64(3) | NO  | now() | UTC | Thời điểm phát sinh sự kiện, chính xác đến mili giây,. |
| 208 | Nhóm Phân quyền (Authorization - IAM) |     | Package |     |     |     | Kiểm soát quyền truy cập từ mức tính năng đến mức dữ liệu |
| 209 | roles | YSQL | Collection |     |     |     | Định nghĩa các vai trò (VD: Admin, Editor) và danh sách mã quyền đi kèm. |
| 210 | roles | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7, giúp tối ưu hóa sắp xếp theo thời gian và sharding,. |
| 211 | roles | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định vai trò này thuộc tổ chức nào (Sharding Key),. |
| 212 | roles | name | VARCHAR(100) | NO  |     | CHECK (LENGTH(name) > 0) | Tên vai trò (VD: Admin, Editor, HR Manager). |
| 213 | roles | description | TEXT | YES | NULL |     | Mô tả chi tiết về trách nhiệm của vai trò này. |
| 214 | roles | type | VARCHAR(20) | NO  | CUSTOM' | CHECK (type IN ('SYSTEM', 'CUSTOM')) | SYSTEM: Vai trò mặc định không thể xóa. CUSTOM: Vai trò do khách hàng tự định nghĩa. |
| 215 | roles | permission\_codes | TEXT\[\] | NO  | {}' |     | Mảng chứa các mã quyền (VD: {'user:view', 'invoice:create'}). Lưu mảng giúp truy vấn nhanh mà không cần join bảng trung gian. |
| 216 | roles | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo vai trò (UTC),. |
| 217 | roles | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật cuối cùng. |
| 218 | roles | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking: Ngăn chặn xung đột khi nhiều Admin cùng sửa cấu hình vai trò,. |
| 219 | permissions | YSQL | Collection |     |     |     | Danh mục các hành động kỹ thuật do lập trình viên định nghĩa cứng trong code. |
| 220 | permissions | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian,. |
| 221 | permissions | code | VARCHAR(100) | NO  |     | UNIQUE, CHECK (LENGTH(code) > 0) | Mã quyền duy nhất dùng trong code (VD: invoice:create, user:view),. |
| 222 | permissions | app_code | VARCHAR(50) | NO  |     | REFERENCES applications(code)    | Liên kết với ứng dụng sở hữu quyền này (VD: HRM, CRM). |
| 222 | permissions | parent_code | VARCHAR(100) | YES  |     | REFERENCES permissions(code)    | Mã của quyền cha để tạo cấu trúc cây phân cấp . |
| 222 | permissions | path | TEXT | NO  |     | REFERENCES applications(code)    | Materialized Path (VD: /HRM/PAYROLL/). Giúp truy vấn cả nhánh quyền cực nhanh. |
| 222 | permissions | is_group | BOOLEAN | NO  | FALSE    |     | TRUE nếu chỉ là thư mục phân nhóm, FALSE nếu là quyền thực thi |
| 222 | permissions | name | VARCHAR(255) | NO  |     |     | Tên hiển thị của quyền trên giao diện quản trị. |
| 223 | permissions | description | TEXT | YES | NULL |     | Mô tả chi tiết ý nghĩa và phạm vi tác động của quyền này. |
| 224 | permissions | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo quyền trong hệ thống (UTC),. |
| 225 | permissions | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật thông tin quyền gần nhất. |
| 226 | user\_roles | YSQL | Collection |     |     |     | Gán vai trò cho thành viên, hỗ trợ phạm vi dữ liệu (scope\_values) như theo phòng ban hoặc khu vực. |
| 227 | user\_roles | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sắp xếp theo thời gian và tránh "hotspot" khi ghi phân tán. |
| 228 | user\_roles | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation), xác định quan hệ này thuộc về khách hàng nào. |
| 229 | user\_roles | member\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) ON DELETE CASCADE | Liên kết với hồ sơ nhân viên trong tổ chức (thay vì User gốc) để quản lý vòng đời nhân sự. |
| 230 | user\_roles | role\_id | UUID | NO  |     | REFERENCES roles(\_id) ON DELETE CASCADE | Vai trò được gán (VD: Manager, Editor). |
| 231 | user\_roles | scope\_type | VARCHAR(50) | NO  | GLOBAL' | CHECK (scope\_type IN ('GLOBAL', 'DEPARTMENT', 'LOCATION', 'PROJECT')) | Phạm vi áp dụng quyền: Toàn cục, theo phòng ban, hoặc theo dự án cụ thể. |
| 232 | user\_roles | scope\_values | TEXT\[\] | NO  | {}' |     | Mảng chứa các UUID của phòng ban/vị trí tương ứng với scope\_type. |
| 233 | user\_roles | assigned\_by | UUID | YES | NULL |     | ID của người thực hiện gán quyền để phục vụ truy vết (Audit). |
| 234 | user\_roles | assigned\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm chính xác quyền được gán (UTC). |
| 235 | relationship\_tuples | YSQL | Collection |     |     |     | Mô hình phân quyền dựa trên quan hệ (ReBAC - Google Zanzibar) cho các kịch bản chia sẻ tài nguyên phức tạp. |
| 236 | relationship\_tuples | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Định danh tổ chức sở hữu quan hệ này (SaaS Isolation). |
| 237 | relationship\_tuples | namespace | VARCHAR(50) | NO  |     | CHECK (LENGTH(namespace) > 0) | Loại tài nguyên (Object Namespace) như: document, folder, project. |
| 238 | relationship\_tuples | object\_id | UUID | NO  |     |     | Định danh cụ thể của tài nguyên (Sử dụng UUID v7 để tối ưu). |
| 239 | relationship\_tuples | relation | VARCHAR(50) | NO  |     |     | Mối quan hệ như: viewer, editor, owner, parent. |
| 240 | relationship\_tuples | subject\_namespace | VARCHAR(50) | NO  |     |     | Loại đối tượng được gán quyền: user, group, hoặc một folder (nếu thừa kế). |
| 241 | relationship\_tuples | subject\_id | UUID | NO  |     |     | Định danh của đối tượng (User/Group ID). |
| 242 | relationship\_tuples | subject\_relation | VARCHAR(50) | YES | NULL |     | Dùng cho quan hệ lồng nhau (VD: "Thành viên của nhóm A"). |
| 243 | relationship\_tuples | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo quan hệ (UTC). |
| 244 | access\_control\_lists | YSQL | Collection |     |     |     | Kiểm soát truy cập chi tiết cho từng tài nguyên cụ thể (VD: Folder, Document). |
| 245 | access\_control\_lists | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7 giúp tối ưu sharding. |
| 246 | access\_control\_lists | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| 247 | access\_control\_lists | resource\_type | VARCHAR(50) | NO  |     | CHECK (LENGTH(resource\_type) > 0) | Loại tài nguyên (VD: 'DASHBOARD', 'REPORT', 'FOLDER'). |
| 248 | access\_control\_lists | resource\_id | UUID | NO  |     |     | ID cụ thể của tài nguyên được phân quyền. |
| 249 | access\_control\_lists | subject\_type | VARCHAR(20) | NO  |     | CHECK (subject\_type IN ('MEMBER', 'GROUP', 'ROLE')) | Loại đối tượng nhận quyền (Thành viên, Nhóm, hoặc Vai trò). |
| 250 | access\_control\_lists | subject\_id | UUID | NO  |     |     | ID của đối tượng nhận quyền (Member ID hoặc Group ID). |
| 251 | access\_control\_lists | action | VARCHAR(50) | NO  |     | CHECK (action IN ('READ', 'WRITE', 'DELETE', 'SHARE')) | Hành động được phép thực hiện trên tài nguyên. |
| 252 | access\_control\_lists | is\_allowed | BOOLEAN | NO  | TRUE |     | TRUE là cho phép, FALSE là chặn cụ thể (Deny). |
| 253 | access\_control\_lists | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC) phục vụ truy vết. |
| 254 | Nhóm Quản trị và Tuân thủ (Governance & Compliance) |     | Package |     |     |     | Đáp ứng các yêu cầu của khách hàng Enterprise lớn |
| 255 | tenant\_domains | YSQL | Collection |     |     |     | Xác thực tên miền sở hữu (VD: @fpt.com) để tự động quản lý thành viên và thực thi SSO. |
| 256 | tenant\_domains | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất (UUID v7) giúp tránh hiện tượng "Hotspot" khi chèn dữ liệu phân tán. |
| 257 | tenant\_domains | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết đến tổ chức sở hữu tên miền này. |
| 258 | tenant\_domains | domain | VARCHAR(255) | NO  |     | UNIQUE, CHECK (domain ~ '^\[a-z0-9.-\]+$') | Tên miền (VD: fpt.com). Phải là duy nhất trên toàn hệ thống để xác định chủ quyền. |
| 259 | tenant\_domains | verification\_status | VARCHAR(20) | NO  | PENDING' | CHECK (status IN ('PENDING', 'VERIFIED')) | Trạng thái xác minh chủ sở hữu tên miền. |
| 260 | tenant\_domains | verification\_method | VARCHAR(20) | YES | NULL | CHECK (method IN ('DNS\_TXT', 'HTML\_FILE')) | Phương thức khách hàng chọn để chứng minh quyền sở hữu (DNS hoặc file HTML). |
| 261 | tenant\_domains | verification\_token | VARCHAR(100) | YES | NULL |     | Mã bí mật khách hàng phải cấu hình vào DNS/Web server để hệ thống đối soát. |
| 262 | tenant\_domains | policy | VARCHAR(20) | NO  | NONE' | CHECK (policy IN ('NONE', 'CAPTURE', 'ENFORCE\_SSO')) | CAPTURE: Tự động đưa user đăng ký bằng email đuôi này vào Tenant. ENFORCE\_SSO: Bắt buộc đăng nhập qua SSO. |
| 263 | tenant\_domains | verified\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm xác thực thành công (UTC). |
| 264 | tenant\_domains | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm bản ghi được tạo (UTC). |
| 265 | tenant\_invitations | YSQL | Collection |     |     |     | Quản lý quy trình mời và gia nhập của người dùng mới. |
| 266 | tenant\_invitations | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp thời gian,. |
| 267 | tenant\_invitations | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định lời mời thuộc về tổ chức nào (SaaS Isolation),. |
| 268 | tenant\_invitations | email | VARCHAR(255) | NO  |     | CHECK (email ~\* '^\[A-Z0-9.\_%+-\]+@\[A-Z0-9.-\]+\\.\[A-Z\]{2,}$') | Email của người nhận lời mời,. |
| 269 | tenant\_invitations | role\_ids | TEXT\[\] | YES | {}' |     | Mảng chứa các mã vai trò (Roles) dự kiến gán cho người dùng sau khi chấp nhận,. |
| 270 | tenant\_invitations | department\_id | UUID | YES | NULL |     | Phòng ban dự kiến người mới sẽ tham gia,. |
| 271 | tenant\_invitations | token | VARCHAR(100) | NO  |     | UNIQUE | Mã bí mật duy nhất đính kèm trong link mời gửi qua email,. |
| 272 | tenant\_invitations | status | VARCHAR(20) | NO  | PENDING' | CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')) | Trạng thái của lời mời (Chờ, Đã nhận, Hết hạn hoặc Bị thu hồi),. |
| 273 | tenant\_invitations | expires\_at | TIMESTAMPTZ | NO  |     | CHECK (expires\_at > created\_at) | Thời điểm link hết hạn (UTC),. |
| 274 | tenant\_invitations | invited\_by | UUID | YES | NULL |     | ID của người gửi lời mời để phục vụ truy vết (Audit),. |
| 275 | tenant\_invitations | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo lời mời (UTC). |
| 276 | access\_reviews | YSQL | Collection |     |     |     | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| 277 | access\_reviews | \_id | UUID | NO  |     | PRIMARY KEY | Định danh đợt rà soát. Sử dụng UUID v7 (sinh từ tầng App) để tối ưu hóa sắp xếp và sharding,,. |
| 278 | access\_reviews | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu (SaaS Isolation). Mỗi Tenant quản lý các đợt rà soát riêng,. |
| 279 | access\_reviews | name | VARCHAR(255) | NO  |     | CHECK (LENGTH(name) > 0) | Tên đợt rà soát (VD: "Rà soát quyền hạn Q4/2024"). |
| 280 | access\_reviews | description | TEXT | YES | NULL |     | Mô tả chi tiết mục tiêu hoặc phạm vi của đợt rà soát này. |
| 281 | access\_reviews | status | VARCHAR(20) | NO  | PENDING' | CHECK (status IN ('PENDING', 'IN\_PROGRESS', 'COMPLETED', 'CANCELLED')) | Trạng thái của đợt rà soát. |
| 282 | access\_reviews | deadline | TIMESTAMPTZ | NO  |     |     | Thời hạn cuối cùng phải hoàn thành việc rà soát. |
| 283 | access\_reviews | created\_by | UUID | NO  |     | REFERENCES users(\_id) | Người khởi tạo đợt rà soát (thường là Security Admin). |
| 284 | access\_reviews | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo đợt rà soát (UTC),. |
| 285 | access\_reviews | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật trạng thái gần nhất. |
| 286 | access\_reviews | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking để tránh xung đột khi nhiều Admin cùng điều chỉnh cấu hình. |
| 287 | access\_review\_items | YSQL | Collection |     |     |     | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| 288 | access\_review\_items | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7,. |
| 289 | access\_review\_items | review\_id | UUID | NO  |     | REFERENCES access\_reviews(\_id) ON DELETE CASCADE | Liên kết với đợt rà soát tổng thể. |
| 290 | access\_review\_items | reviewer\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) | Người chịu trách nhiệm rà soát (thường là Manager trực tiếp). |
| 291 | access\_review\_items | target\_member\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) | Nhân viên đang được kiểm tra quyền hạn. |
| 292 | access\_review\_items | role\_id | UUID | NO  |     | REFERENCES roles(\_id) | Vai trò cụ thể đang được xem xét để giữ lại hoặc thu hồi. |
| 293 | access\_review\_items | decision | VARCHAR(20) | NO  | PENDING' | CHECK (decision IN ('PENDING', 'KEEP', 'REVOKE')) | Quyết định: Đang chờ, Giữ lại, hoặc Thu hồi quyền. |
| 294 | access\_review\_items | reason | TEXT | YES | NULL |     | Lý do cho quyết định (bắt buộc nếu chọn REVOKE). |
| 295 | access\_review\_items | reviewed\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm người rà soát thực hiện xác nhận,. |
| 296 | access\_review\_items | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm mục rà soát được tạo (UTC). |
| 297 | access\_review\_items | updated\_at | TIMESTAMPTZ | NO  | now() | CHECK (updated\_at >= created\_at) | Thời điểm cập nhật trạng thái mục rà soát. |
| 298 | scim\_directories | YSQL | Collection |     |     |     | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| 299 | scim\_directories | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, giúp sắp xếp dữ liệu theo thời gian thực,. |
| 300 | scim\_directories | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | ID của tổ chức sở hữu kết nối thư mục này (SaaS Isolation),. |
| 301 | scim\_directories | provider\_type | VARCHAR(20) | NO  |     | CHECK (provider\_type IN ('AZURE\_AD', 'OKTA', 'ONELOGIN', 'CUSTOM')) | Loại nhà cung cấp định danh (IdP) như Azure AD, Okta.... |
| 302 | scim\_directories | scim\_token\_hash | TEXT | NO  |     | UNIQUE | Bản băm của Bearer Token dùng để xác thực các request SCIM từ IdP gửi đến. |
| 303 | scim\_directories | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái kích hoạt của kết nối. |
| 304 | scim\_directories | last\_synced\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm cuối cùng IdP thực hiện đồng bộ dữ liệu. |
| 305 | scim\_directories | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo cấu hình kết nối (UTC),. |
| 306 | scim\_directories | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Sử dụng cho cơ chế Optimistic Locking khi cập nhật cấu hình. |
| 307 | scim\_mappings | YSQL | Collection |     |     |     | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| 308 | scim\_mappings | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7,. |
| 309 | scim\_mappings | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | ID của tổ chức sở hữu ánh xạ này để đảm bảo cô lập dữ liệu (SaaS Isolation),. |
| 310 | scim\_mappings | directory\_id | UUID | NO  |     | REFERENCES scim\_directories(\_id) ON DELETE CASCADE | Liên kết với cấu hình kết nối thư mục SCIM cụ thể. |
| 311 | scim\_mappings | external\_id | VARCHAR(255) | NO  |     |     | ID của đối tượng (User/Group) được cung cấp bởi hệ thống IdP bên ngoài (Azure AD/Okta). |
| 312 | scim\_mappings | internal\_entity\_type | VARCHAR(20) | NO  |     | CHECK (internal\_entity\_type IN ('USER', 'GROUP')) | Phân loại đối tượng ánh xạ là Người dùng hoặc Nhóm. |
| 313 | scim\_mappings | internal\_entity\_id | UUID | NO  |     |     | ID của đối tượng tương ứng trong hệ thống nội bộ (trỏ đến users hoặc user\_groups). |
| 314 | scim\_mappings | data\_hash | VARCHAR(64) | YES | NULL |     | Mã băm (Checksum) để so sánh và phát hiện thay đổi dữ liệu từ lần đồng bộ trước. |
| 315 | scim\_mappings | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật ánh xạ lần cuối (UTC),. |
| 316 | legal\_documents | YSQL | Collection |     |     |     | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| 317 | legal\_documents | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian thực. |
| 318 | legal\_documents | type | VARCHAR(50) | NO  |     | CHECK (type IN ('TERMS\_OF\_SERVICE', 'PRIVACY\_POLICY', 'COOKIE\_POLICY', 'EULA')) | Phân loại loại văn bản pháp lý. |
| 319 | legal\_documents | version | VARCHAR(20) | NO  |     |     | Phiên bản của văn bản (VD: 'v1.0', '2024-JAN'). |
| 320 | legal\_documents | title | TEXT | NO  |     | CHECK (LENGTH(title) > 0) | Tiêu đề hiển thị của văn bản. |
| 321 | legal\_documents | content\_url | TEXT | NO  |     | CHECK (content\_url ~\* '^https?://') | Đường dẫn đến nội dung văn bản trên Object Storage. Dùng TEXT thay vì VARCHAR(255) để tránh rủi ro URL dài. |
| 322 | legal\_documents | is\_active | BOOLEAN | NO  | FALSE |     | Đánh dấu phiên bản hiện hành. Chỉ một phiên bản trên mỗi loại được là TRUE. |
| 323 | legal\_documents | published\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm công bố văn bản chính thức (UTC). |
| 324 | legal\_documents | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi trong hệ thống. |
| 325 | legal\_documents | version\_locking | BIGINT | NO  | 1   |     | Cơ chế Optimistic Locking để tránh xung đột khi cập nhật. |
| 326 | user\_consents | YSQL | Collection |     |     |     | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| 327 | user\_consents | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding và sắp xếp theo thời gian thực,. |
| 328 | user\_consents | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | ID của người dùng thực hiện đồng ý. |
| 329 | user\_consents | document\_id | UUID | NO  |     | REFERENCES legal\_documents(\_id) | Liên kết đến phiên bản văn bản pháp lý cụ thể. |
| 330 | user\_consents | agreed\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm chính xác người dùng bấm nút đồng ý (UTC),. |
| 331 | user\_consents | ip\_address | INET | NO  |     |     | Địa chỉ IP của người dùng tại thời điểm đồng ý (Phục vụ truy vết/Audit),. |
| 332 | user\_consents | user\_agent | TEXT | YES | NULL |     | Thông tin trình duyệt/thiết bị của người dùng để tăng tính pháp lý,. |
| 333 | user\_consents | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking để quản lý phiên bản dòng dữ liệu,. |
| 334 | security\_audit\_logs | ClickHouse | Collection |     |     |     | (Nhật ký an ninh lõi): Tập trung vào các sự kiện an ninh cấp độ hệ thống như: đăng nhập thất bại, gán vai trò (role) cho người dùng, tạo API Key, hoặc thay đổi chính sách bảo mật |
| 335 | security\_audit\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian,. |
| 336 | security\_audit\_logs | tenant\_id | UUID | NO  |     |     | Định danh tổ chức sở hữu hành động này để phân vùng dữ liệu,. |
| 337 | security\_audit\_logs | actor\_id | UUID | NO  |     |     | ID của người dùng thực hiện hành động. |
| 338 | security\_audit\_logs | impersonator\_id | Nullable(UUID) | YES | NULL |     | ID nhân viên hỗ trợ nếu đang sử dụng tính năng "Impersonation" (giả danh),. |
| 339 | security\_audit\_logs | event\_category | Enum8(...) | NO  |     | IAM, AUTH, BILLING, DATA | Nhóm sự kiện chính để lọc nhanh (Ví dụ: Bảo mật, Thanh toán),. |
| 340 | security\_audit\_logs | event\_action | String | NO  |     |     | Hành động cụ thể (Ví dụ: ROLE\_ASSIGNED, API\_KEY\_CREATED). |
| 341 | security\_audit\_logs | target\_id | Nullable(UUID) | YES | NULL |     | ID của đối tượng bị tác động (Ví dụ: ID của User bị khóa). |
| 342 | security\_audit\_logs | resource\_type | String | NO  |     |     | Loại tài nguyên bị tác động (Ví dụ: USER, INVOICE, ROLE). |
| 343 | security\_audit\_logs | ip\_address | IPv6 | NO  |     |     | Địa chỉ IP của người thực hiện (Lưu IPv6 để bao quát cả IPv4). |
| 344 | security\_audit\_logs | user\_agent | String | NO  |     |     | Thông tin trình duyệt và hệ điều hành. |
| 345 | security\_audit\_logs | details | String | NO  | {}' |     | Lưu chi tiết thay đổi dưới dạng JSON String (Dùng JSONExtract khi truy vấn),. |
| 346 | security\_audit\_logs | created\_at | DateTime64(3) | NO  | now() | UTC | Thời điểm xảy ra sự kiện, chính xác đến mili giây,. |
| 347 | user\_delegations | YSQL | Collection |     |     |     | Cho phép ủy quyền hành động (Impersonation) có thời hạn và có kiểm soát. |
| 348 | user\_delegations | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, giúp sắp xếp theo thời gian và tối ưu sharding. |
| 349 | user\_delegations | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Đảm bảo tính cô lập dữ liệu giữa các tổ chức (SaaS Isolation). |
| 350 | user\_delegations | delegator\_id | UUID | NO  |     | REFERENCES users(\_id) | ID của người ủy quyền (người cho đi quyền hạn - ví dụ: Giám đốc). |
| 351 | user\_delegations | delegatee\_id | UUID | NO  |     | REFERENCES users(\_id) | ID của người được ủy quyền (người nhận quyền - ví dụ: Thư ký). |
| 352 | user\_delegations | scopes | TEXT\[\] | NO  | {}' |     | Mảng danh sách các quyền được phép thực hiện (VD: \['calendar:read', 'email:send'\]). |
| 353 | user\_delegations | starts\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm việc ủy quyền bắt đầu có hiệu lực. |
| 354 | user\_delegations | expires\_at | TIMESTAMPTZ | NO  |     | CHECK (expires\_at > starts\_at) | Thời điểm hết hạn ủy quyền (bắt buộc phải có hạn để đảm bảo an ninh). |
| 355 | user\_delegations | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái kích hoạt, cho phép thu hồi quyền nhanh chóng bằng tay. |
| 356 | user\_delegations | reason | TEXT | YES | NULL |     | Lý do ủy quyền (phục vụ mục đích tra soát/audit). |
| 357 | user\_delegations | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm bản ghi được tạo (UTC). |
| 358 | Nhóm Quản lý Truy cập (Access Management) |     | Package |     |     |     |     |
| 359 | api\_keys | YSQL | Collection |     |     |     |     |
| 360 | api\_keys | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian thực. |
| 361 | api\_keys | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết đến tổ chức (Tenant) sở hữu API Key này. |
| 362 | api\_keys | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên gợi nhớ cho Key (Ví dụ: "Tích hợp ERP", "Sync dữ liệu"). |
| 363 | api\_keys | key\_prefix | VARCHAR(10) | NO  |     |     | 10 ký tự đầu của Key để hiển thị trên giao diện quản trị (VD: sk\_live\_...). |
| 364 | api\_keys | key\_hash | TEXT | NO  |     | UNIQUE | Tuyệt đối không lưu Key gốc. Chỉ lưu bản băm (Hash) để đối soát khi xác thực. |
| 365 | api\_keys | scopes | TEXT\[\] | NO  | {}' |     | Mảng danh sách các quyền hạn được cấp (VD: \['crm:read', 'hrm:write'\]). |
| 366 | api\_keys | allowed\_ips | CIDR\[\] | YES | NULL |     | Giới hạn các dải IP được phép truy cập (IP Whitelist) để tăng cường bảo mật. |
| 367 | api\_keys | expires\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm Key hết hạn. Nếu NULL là vô hạn (không khuyến nghị cho Enterprise). |
| 368 | api\_keys | last\_used\_at | TIMESTAMPTZ | YES | NULL |     | Ghi lại thời điểm cuối cùng Key này được sử dụng để truy cập hệ thống. |
| 369 | api\_keys | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo Key. |
| 370 | api\_keys | created\_by | UUID | YES | NULL | REFERENCES users(\_id) | ID của người dùng thực hiện tạo Key này. |
| 371 | api\_keys | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking để quản lý phiên bản dòng dữ liệu. |
| 372 | service\_accounts | YSQL | Collection |     |     |     |     |
| 373 | service\_accounts | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp tối ưu sharding. |
| 374 | service\_accounts | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định tài khoản này thuộc về tổ chức nào,. |
| 375 | service\_accounts | name | TEXT | NO  |     | CHECK (LENGTH(name) > 0) | Tên hiển thị (VD: "GitHub Action Bot", "ERP Sync"). |
| 376 | service\_accounts | description | TEXT | YES | NULL |     | Mô tả chi tiết mục đích sử dụng của tài khoản. |
| 377 | service\_accounts | client\_id | VARCHAR(64) | NO  |     | UNIQUE | Mã định danh duy nhất dùng để xác thực thay cho email. |
| 378 | service\_accounts | client\_secret\_hash | TEXT | NO  |     |     | Bản băm mật khẩu của tài khoản máy. |
| 379 | service\_accounts | member\_id | UUID | NO  |     | REFERENCES tenant\_members(\_id) | Liên kết sang bảng thành viên để gán quyền RBAC như người thật. |
| 380 | service\_accounts | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái kích hoạt của tài khoản. |
| 381 | service\_accounts | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo tài khoản (UTC). |
| 382 | service\_accounts | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 383 | service\_accounts | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| 384 | user\_devices | YSQL | Collection |     |     |     |     |
| 385 | user\_devices | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian thực. |
| 386 | user\_devices | user\_id | UUID | NO  |     | REFERENCES users(\_id) ON DELETE CASCADE | Liên kết với tài khoản người dùng chủ sở hữu thiết bị. |
| 387 | user\_devices | device\_fingerprint | VARCHAR(255) | NO  |     | UNIQUE | Mã định danh thiết bị (được tạo từ trình duyệt, OS và phần cứng). |
| 388 | user\_devices | name | TEXT | YES | NULL |     | Tên gợi nhớ do người dùng đặt (VD: "Macbook Pro của An"). |
| 389 | user\_devices | user\_agent\_parsed | JSONB | NO  | {}' |     | Chứa thông tin chi tiết đã phân tách từ User Agent (OS, phiên bản trình duyệt). |
| 390 | user\_devices | trust\_status | VARCHAR(20) | NO  | UNTRUSTED' | CHECK (trust\_status IN ('UNTRUSTED', 'TRUSTED', 'BLOCKED')) | Trạng thái tin cậy của thiết bị để quyết định có cần yêu cầu MFA hay không. |
| 391 | user\_devices | last\_ip | INET | YES | NULL |     | Địa chỉ IP cuối cùng thiết bị này sử dụng để truy cập. |
| 392 | user\_devices | last\_active\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cuối cùng thiết bị hoạt động trên hệ thống. |
| 393 | user\_devices | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm thiết bị lần đầu được ghi nhận. |
| 394 | tenant\_app\_routes | YSQL | Collection |     |     |     |     |
| 395 | tenant\_app\_routes | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 396 | tenant\_app\_routes | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Liên kết với Tenant sở hữu route này. |
| 397 | tenant\_app\_routes | app\_code | VARCHAR(50) | NO  |     | CHECK (LENGTH(app\_code) > 0) | Mã ứng dụng đích (VD: HRM, CRM, DASHBOARD). |
| 398 | tenant\_app\_routes | domain | VARCHAR(255) | NO  |     | CHECK (domain ~ '^\[a-z0-9.-\]+$') | Tên miền truy cập (VD: hrm.fpt.com). Chỉ chứa chữ thường, số, dấu chấm và gạch ngang. |
| 399 | tenant\_app\_routes | path\_prefix | VARCHAR(100) | NO  | /'  | CHECK (path\_prefix ~ '^/\[a-z0-9-/\]\*$') | Đường dẫn tiền tố (VD: /hrm). Phải bắt đầu bằng dấu /. |
| 400 | tenant\_app\_routes | is\_primary | BOOLEAN | NO  | FALSE |     | TRUE nếu là Domain chính để hệ thống sinh link (Canonical URL). |
| 401 | tenant\_app\_routes | is\_custom\_domain | BOOLEAN | NO  | FALSE |     | TRUE nếu là tên miền riêng của khách, FALSE nếu là subdomain hệ thống. |
| 402 | tenant\_app\_routes | ssl\_status | VARCHAR(20) | NO  | NONE' | CHECK (ssl\_status IN ('NONE', 'PENDING', 'ACTIVE', 'FAILED')) | Trạng thái chứng chỉ HTTPS cho custom domain. |
| 403 | tenant\_app\_routes | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo cấu hình định tuyến (UTC). |
| 404 | tenant\_app\_routes | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 405 | tenant\_app\_routes | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking để chống ghi đè đồng thời. |
| 406 | tenant\_rate\_limits | YSQL | Collection |     |     |     |     |
| 407 | tenant\_rate\_limits | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 408 | tenant\_rate\_limits | tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | Liên kết tới Tenant. Nếu NULL nghĩa là áp dụng cho Global hoặc Package. |
| 409 | tenant\_rate\_limits | package\_id | UUID | YES | NULL | REFERENCES packages(\_id) | Liên kết tới gói cước. Dùng để áp giới hạn theo gói (VD: Gói Free giới hạn thấp hơn). |
| 410 | tenant\_rate\_limits | api\_group | VARCHAR(50) | NO  |     | CHECK (LENGTH(api\_group) > 0) | Nhóm API cần giới hạn (VD: REPORTING\_API, AUTH\_API, CORE\_API). |
| 411 | tenant\_rate\_limits | limit\_count | INT | NO  |     | CHECK (limit\_count > 0) | Số lượng request tối đa được phép. |
| 412 | tenant\_rate\_limits | window\_seconds | INT | NO  | 60  | CHECK (window\_seconds > 0) | Khoảng thời gian (giây) áp dụng giới hạn. |
| 413 | tenant\_rate\_limits | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái hiệu lực của cấu hình. |
| 414 | tenant\_rate\_limits | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo (UTC). |
| 415 | tenant\_rate\_limits | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 416 | tenant\_rate\_limits | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| 417 | oauth\_clients | YSQL | Collection |     |     |     |     |
| 418 | oauth\_clients | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 để tối ưu hóa việc sắp xếp theo thời gian và sharding. |
| 419 | oauth\_clients | tenant\_id | UUID | YES | NULL | REFERENCES tenants(\_id) ON DELETE CASCADE | Xác định ứng dụng này thuộc về tổ chức nào (nếu là ứng dụng nội bộ). |
| 420 | oauth\_clients | client\_id | VARCHAR(64) | NO  |     | UNIQUE | Mã định danh công khai của ứng dụng dùng để nhận diện khi đăng nhập. |
| 421 | oauth\_clients | client\_secret\_hash | TEXT | NO  |     |     | Bản băm bảo mật của mã bí mật (Secret Key). Tuyệt đối không lưu plain-text. |
| 422 | oauth\_clients | name | TEXT | NO  |     | CHECK (length(name) > 0) | Tên hiển thị của ứng dụng khách (Ví dụ: "Mobile App", "Portal"). |
| 423 | oauth\_clients | logo\_url | TEXT | YES | NULL |     | URL ảnh đại diện của ứng dụng hiển thị trên màn hình xin quyền. |
| 424 | oauth\_clients | redirect\_uris | TEXT\[\] | NO  |     |     | Mảng các URL được phép quay lại sau khi xác thực thành công để chống tấn công chuyển hướng. |
| 425 | oauth\_clients | allowed\_scopes | TEXT\[\] | YES | NULL |     | Danh sách các quyền (scopes) mà ứng dụng này được phép yêu cầu (Ví dụ: openid, profile). |
| 426 | oauth\_clients | is\_trusted | BOOLEAN | NO  | FALSE |     | Nếu TRUE, hệ thống sẽ tự động phê duyệt mà không hiển thị màn hình hỏi ý kiến người dùng (Consent). |
| 427 | oauth\_clients | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi chuẩn UTC. |
| 428 | oauth\_clients | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cấu hình gần nhất. |
| 429 | webhooks | YSQL | Collection |     |     |     |     |
| 430 | webhooks | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 431 | webhooks | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) ON DELETE CASCADE | Thuộc sở hữu của Tenant nào. |
| 432 | webhooks | target\_url | TEXT | NO  |     | CHECK (target\_url ~\* '^https?://') | URL đích nhận thông báo. Dùng TEXT để tránh giới hạn độ dài. |
| 433 | webhooks | secret\_key | TEXT | NO  |     |     | Dùng để ký (sign) payload, giúp bên nhận xác thực dữ liệu từ hệ thống. |
| 434 | webhooks | subscribed\_events | TEXT\[\] | NO  |     |     | Mảng danh sách các sự kiện đăng ký (VD: \['user.created', 'invoice.paid'\]). |
| 435 | webhooks | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái hoạt động của Webhook. |
| 436 | webhooks | failure\_count | INT | NO  | 0   | CHECK (failure\_count >= 0) | Số lần gửi lỗi liên tiếp. Nếu quá 10 lần, hệ thống tự động tắt (is\_active = FALSE). |
| 437 | webhooks | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo (UTC). |
| 438 | webhooks | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 439 | webhooks | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Cơ chế Optimistic Locking chống ghi đè đồng thời. |
| 440 | api\_usage\_logs | ClickHouse | Collection |     |     |     |     |
| 441 | api\_usage\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| 442 | api\_usage\_logs | tenant\_id | UUID | NO  |     |     | Định danh khách hàng sở hữu log. |
| 443 | api\_usage\_logs | app\_code | String | NO  |     | CHECK (length(app\_code) > 0) | Mã ứng dụng (VD: HRM, CRM, POS),. |
| 444 | api\_usage\_logs | api\_endpoint | String | NO  |     |     | Đường dẫn API đã gọi. |
| 445 | api\_usage\_logs | api\_method | Enum8(...) | NO  |     | GET' = 1, 'POST' = 2, 'PUT' = 3, 'DELETE' = 4, 'PATCH' = 5, 'OPTIONS' = 6 | Phương thức HTTP (Dùng Enum để nén dữ liệu),. |
| 446 | api\_usage\_logs | status\_code | Int16 | NO  |     |     | Mã phản hồi HTTP (VD: 200, 401, 500). |
| 447 | api\_usage\_logs | request\_size | Int64 | NO  | 0   | CHECK (request\_size >= 0) | Dung lượng request (bytes) để tính bandwidth. |
| 448 | api\_usage\_logs | response\_size | Int64 | NO  | 0   | CHECK (response\_size >= 0) | Dung lượng response (bytes) để tính bandwidth. |
| 449 | api\_usage\_logs | latency\_ms | Int32 | NO  |     |     | Thời gian xử lý của API (mili giây). |
| 450 | api\_usage\_logs | api\_key\_id | Nullable(UUID) | YES | NULL |     | ID của API Key nếu dùng Machine-to-Machine,. |
| 451 | api\_usage\_logs | created\_at | DateTime64(3) | NO  | now() | UTC | Thời điểm ghi log, độ chính xác mili-giây,. |
| 452 | webhook\_delivery\_logs | ClickHouse | Collection |     |     |     |     |
| 453 | webhook\_delivery\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 454 | webhook\_delivery\_logs | tenant\_id | UUID | NO  |     |     | ID tổ chức sở hữu webhook (Dùng để phân vùng truy vấn). |
| 455 | webhook\_delivery\_logs | webhook\_id | UUID | NO  |     |     | Tham chiếu đến cấu hình webhook gốc tại YugabyteDB. |
| 456 | webhook\_delivery\_logs | event\_type | String | NO  |     |     | Loại sự kiện (Ví dụ: user.created, invoice.paid). |
| 457 | webhook\_delivery\_logs | target\_url | String | NO  |     | CHECK (target\_url ~\* '^https?://') | URL đích nhận dữ liệu. |
| 458 | webhook\_delivery\_logs | payload | String | NO  |     |     | Nội dung dữ liệu (JSON) đã gửi đi. |
| 459 | webhook\_delivery\_logs | response\_body | String | YES | NULL |     | Nội dung phản hồi từ hệ thống của khách hàng. |
| 460 | webhook\_delivery\_logs | status\_code | Int16 | NO  |     |     | Mã trạng thái HTTP trả về (Ví dụ: 200, 404, 500). |
| 461 | webhook\_delivery\_logs | is\_success | Bool | NO  |     |     | Trạng thái gửi thành công hay thất bại. |
| 462 | webhook\_delivery\_logs | latency\_ms | Int32 | NO  |     |     | Thời gian xử lý của phía khách hàng (mili giây). |
| 463 | webhook\_delivery\_logs | attempt\_number | Int8 | NO  | 1   |     | Số lần thử lại (Retry) cho sự kiện này. |
| 464 | webhook\_delivery\_logs | created\_at | DateTime64(3) | NO  | now() | UTC | Thời điểm thực hiện gửi tin (Chính xác đến ms). |
| 465 | audit\_logs | ClickHouse | Collection |     |     |     | Nhật ký kiểm tra hệ thống. Lưu vết toàn bộ các hành động thay đổi dữ liệu của người dùng trên hệ thống. Đặc biệt, bảng này trong mô hình Enterprise sẽ bao gồm trường impersonator\_id để ghi lại định danh của nhân viên hỗ trợ nếu họ đang sử dụng tính năng "Impersonation" (giả danh khách hàng) để xử lý sự cố |
| 466 | audit\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| 467 | audit\_logs | tenant\_id | UUID | NO  |     |     | Định danh khách hàng (Dùng để lọc dữ liệu theo Tenant),. |
| 468 | audit\_logs | user\_id | UUID | NO  |     |     | ID của người dùng thực hiện hành động. |
| 469 | audit\_logs | impersonator\_id | UUID | YES | NULL |     | ID nhân viên Support nếu đang sử dụng tính năng "Impersonation",. |
| 470 | audit\_logs | event\_time | DateTime64(3) | NO  | now() | UTC | Thời điểm xảy ra sự kiện, chính xác đến mili giây,. |
| 471 | audit\_logs | action | String | NO  |     | CHECK (length(action) > 0) | Loại hành động (VD: UPDATE\_SALARY, DELETE\_USER),. |
| 472 | audit\_logs | resource | String | NO  |     |     | Tên thực thể bị tác động (VD: employees, invoices),. |
| 473 | audit\_logs | resource\_id | String | YES | NULL |     | ID của bản ghi cụ thể bị tác động. |
| 474 | audit\_logs | details | String | YES | NULL |     | Lưu snapshot thay đổi (thường là JSON lưu Diff cũ/mới),. |
| 475 | audit\_logs | ip\_address | String | NO  |     |     | Địa chỉ IP của người thực hiện. |
| 476 | audit\_logs | user\_agent | String | YES | NULL |     | Thông tin trình duyệt và thiết bị. |
| 477 | audit\_logs | status | Enum8(...) | NO  | SUCCESS' | SUCCESS'=1, 'FAILED'=2 | Trạng thái thực hiện hành động,. |
| 478 | outbox\_events | YSQL | Collection |     |     |     |     |
| 479 | outbox\_events | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sharding và sắp xếp thời gian,. |
| 480 | outbox\_events | tenant\_id | UUID | NO  |     | REFERENCES tenants(\_id) | Xác định sự kiện thuộc về khách hàng nào để hỗ trợ lọc và phân mảnh dữ liệu,. |
| 481 | outbox\_events | aggregate\_type | VARCHAR(50) | NO  |     | CHECK (length(aggregate\_type) > 0) | Loại thực thể phát sinh sự kiện (VD: TENANT, USER, ORDER). |
| 482 | outbox\_events | aggregate\_id | UUID | NO  |     |     | ID của bản ghi nghiệp vụ cụ thể vừa thay đổi. |
| 483 | outbox\_events | event\_type | VARCHAR(50) | NO  |     |     | Tên hành động cụ thể (VD: TENANT\_CREATED, PLAN\_UPGRADED). |
| 484 | outbox\_events | payload | JSONB | NO  | {}' |     | Dữ liệu snapshot của thực thể tại thời điểm phát sinh sự kiện để các service khác xử lý,. |
| 485 | outbox\_events | status | VARCHAR(20) | NO  | PENDING' | CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')) | Trạng thái xử lý của sự kiện bởi Event Worker. |
| 486 | outbox\_events | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm sự kiện được tạo ra (chuẩn UTC),. |
| 487 | outbox\_events | published\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm sự kiện đã được đẩy thành công sang Kafka. |
| 488 | user\_registration\_logs | ClickHouse | Collection |     |     |     |     |
| 489 | user\_registration\_logs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh chuẩn UUID v7 để tối ưu sắp xếp thời gian. |
| 490 | user\_registration\_logs | tenant\_id | UUID | NO  |     |     | ID của tổ chức mà người dùng tham gia. |
| 491 | user\_registration\_logs | user\_id | UUID | NO  |     |     | ID gốc của người dùng bên bảng users. |
| 492 | user\_registration\_logs | registration\_source | Enum8(...) | NO  | DIRECT' | DIRECT'=1, 'SSO'=2, 'INVITE'=3 | Nguồn đăng ký (Trực tiếp, qua SSO, hoặc được mời). |
| 493 | user\_registration\_logs | data\_region | String | NO  |     |     | Vùng lưu trữ dữ liệu (VD: ap-southeast-1). |
| 494 | user\_registration\_logs | created\_at | DateTime64(3) | NO  | now() | UTC | Thời điểm đăng ký chính xác đến mili-giây. |
| 495 | Nhóm Billing & FinOps |     | Package |     |     |     |     |
| 496 | Danh mục Sản phẩm & Gói dịch vụ |     | Package |     |     |     | Đây là nơi quy định các "nguyên liệu" đầu vào của hệ thống trước khi đóng gói thành các gói cước thương mại. |
| 497 | saas\_products | YSQL | Collection |     |     |     | (Dòng sản phẩm): Lưu trữ thông tin về các dòng sản phẩm lớn của doanh nghiệp (ví dụ: "Bộ giải pháp Nhân sự", "Hệ thống CRM"). Bảng này bao gồm mã sản phẩm, tên, mô tả và các thuộc tính cơ bản. |
| 498 | saas\_products | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và tối ưu sharding,. |
| 499 | saas\_products | code | VARCHAR(50) | NO  |     | UNIQUE, CHECK (~ '^\[a-z0-9-\]+$') | Mã dòng sản phẩm (Slug). Ví dụ: hrm-suite, crm-platform. Chỉ chứa chữ thường, số và gạch ngang,. |
| 500 | saas\_products | name | TEXT | NO  |     | CHECK (length(name) > 0) | Tên sản phẩm hiển thị. |
| 501 | saas\_products | product\_type | VARCHAR(20) | NO  | APP' | CHECK (product\_type IN ('APP', 'DOMAIN', 'SSL', 'SERVICE')) | Phân loại sản phẩm để xử lý logic: Ứng dụng, Tên miền, SSL hoặc Dịch vụ tư vấn. |
| 502 | saas\_products | description | TEXT | YES | NULL |     | Mô tả chi tiết sản phẩm. Dùng TEXT để không giới hạn độ dài,. |
| 503 | saas\_products | base\_price | NUMERIC(19,4) | NO  | 0   | CHECK (base\_price >= 0) | Giá niêm yết cơ bản. Sử dụng NUMERIC để đảm bảo chính xác tuyệt đối trong tài chính,. |
| 504 | saas\_products | currency | VARCHAR(3) | NO  | VND' | CHECK (length(currency) = 3) | Mã tiền tệ theo chuẩn ISO 4217 (VND, USD,...),. |
| 505 | saas\_products | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái cho phép kinh doanh sản phẩm này,. |
| 506 | saas\_products | metadata | JSONB | NO  | {}' |     | Chứa các thông tin động, thuộc tính riêng biệt tùy theo loại sản phẩm,. |
| 507 | saas\_products | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (chuẩn UTC),. |
| 508 | saas\_products | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 509 | saas\_products | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Hỗ trợ Soft Delete để bảo toàn dữ liệu lịch sử. |
| 510 | saas\_products | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Sử dụng cho Optimistic Locking, ngăn chặn ghi đè dữ liệu khi nhiều người cùng sửa,. |
| 511 | applications | YSQL | Collection |     |     |     | (Danh sách ứng dụng): Định nghĩa các đơn vị phần mềm kỹ thuật cụ thể (ví dụ: "App Tuyển dụng", "App Chấm công", "App Quản lý kho"). |
| 512 | applications | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7 giúp sắp xếp theo thời gian,. |
| 513 | applications | code | VARCHAR(50) | NO  |     | UNIQUE, CHECK (code ~ '^\[A-Z0-9\_\]+$') | Mã ứng dụng kỹ thuật (VD: HRM\_RECRUIT). Chỉ chứa chữ hoa, số và gạch dưới. |
| 514 | applications | name | VARCHAR(255) | NO  |     | CHECK (length(name) > 0) | Tên hiển thị của ứng dụng. |
| 515 | applications | description | TEXT | YES | NULL |     | Mô tả chi tiết chức năng của ứng dụng. |
| 516 | applications | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái bật/tắt ứng dụng trên toàn hệ thống,. |
| 517 | applications | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (chuẩn UTC),. |
| 518 | applications | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật dữ liệu gần nhất. |
| 519 | applications | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm xóa mềm (Soft Delete). |
| 520 | applications | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Dùng cho cơ chế Optimistic Locking, chống ghi đè dữ liệu đồng thời. |
| 521 | app\_capabilities | YSQL | Collection |     |     |     | (Định nghĩa tính năng & giới hạn): Lưu danh sách các tính năng (Boolean) và giới hạn (Number) mà từng ứng dụng hỗ trợ (ví dụ: max\_users, storage\_gb). |
| 522 | app\_capabilities | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 523 | app\_capabilities | app\_code | VARCHAR(50) | NO  |     | REFERENCES applications(code) | Tham chiếu đến mã ứng dụng kỹ thuật. |
| 524 | app\_capabilities | code | VARCHAR(50) | NO  |     | CHECK (code ~ '^\[a-z0-9\_\]+$') | Mã định danh tính năng/hạn mức (VD: allow\_sso, max\_users). |
| 525 | app\_capabilities | name | VARCHAR(255) | NO  |     | CHECK (length(name) > 0) | Tên hiển thị của khả năng. |
| 526 | app\_capabilities | type | VARCHAR(20) | NO  |     | CHECK (type IN ('BOOLEAN', 'NUMBER')) | Phân loại: BOOLEAN (Tính năng) hoặc NUMBER (Hạn mức). |
| 527 | app\_capabilities | default\_value | JSONB | NO  |     |     | Giá trị mặc định (VD: true hoặc 10). Dùng JSONB để linh hoạt kiểu dữ liệu. |
| 528 | app\_capabilities | description | TEXT | YES | NULL |     | Mô tả chi tiết về tính năng hoặc hạn mức này. |
| 529 | app\_capabilities | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái cho phép sử dụng khả năng này để đóng gói. |
| 530 | app\_capabilities | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (chuẩn UTC). |
| 531 | app\_capabilities | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 532 | app\_capabilities | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Hỗ trợ Soft Delete (Xóa mềm). |
| 533 | app\_capabilities | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Sử dụng cho Optimistic Locking. |
| 534 | service\_packages | YSQL | Collection |     |     |     | (Danh mục gói cước): Định nghĩa các gói Combo bán hàng (ví dụ: Gói Starter, Pro, Enterprise). Bảng này sử dụng cột included\_apps\_config dạng JSONB để lưu cấu hình các ứng dụng và giới hạn mặc định đi kèm trong gói. |
| 535 | service\_packages | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 536 | service\_packages | saas\_product\_id | UUID | NO  |     | REFERENCES products(\_id) | Thuộc dòng sản phẩm chính nào (VD: Bộ giải pháp Nhân sự). |
| 537 | service\_packages | code | VARCHAR(50) | NO  |     | UNIQUE, CHECK (code ~ '^\[a-z0-9-\]+$') | Mã gói cước (Slug). Chỉ chứa chữ thường, số, gạch ngang (VD: hrm-pro-monthly). |
| 538 | service\_packages | name | VARCHAR(255) | NO  |     | CHECK (length(name) > 0) | Tên gói cước hiển thị trên báo giá/hóa đơn. |
| 539 | service\_packages | description | TEXT | YES | NULL |     | Mô tả chi tiết các quyền lợi của gói cước. |
| 540 | service\_packages | price\_amount | NUMERIC(19,4) | NO  | 0   | CHECK (price\_amount >= 0) | Giá niêm yết của gói. Dùng NUMERIC để đảm bảo chính xác tuyệt đối. |
| 541 | service\_packages | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ theo chuẩn ISO 4217. |
| 542 | service\_packages | entitlements\_config | JSONB | NO  | {}' |     | Chứa cấu hình lồng nhau về Apps, Features và Limits (VD: Gói này có HRM và CRM).  <br>Một bản ghi entitlements\_config điển hình cho một gói "Combo Enterprise" có thể trông như sau:  <br>{  <br>"HRM\_RECRUIT": {  <br>"features": {  <br>"ai\_screening": true,  <br>"custom\_email": true  <br>},  <br>"limits": {  <br>"job\_posts": 100,  <br>"cv\_storage": 50  <br>}  <br>},  <br>"HRM\_TIMEKEEPING": {  <br>"features": {  <br>"face\_id": true  <br>},  <br>"limits": {  <br>"max\_locations": 5  <br>}  <br>}  <br>} |
| 543 | service\_packages | status | VARCHAR(20) | NO  | ACTIVE' | CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')) | Trạng thái gói: Đang bán, Ngừng bán, hoặc Lưu trữ. |
| 544 | service\_packages | is\_public | BOOLEAN | NO  | TRUE |     | Gói cước công khai hay gói thiết kế riêng (Custom) cho khách VIP. |
| 545 | service\_packages | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo gói (UTC). |
| 546 | service\_packages | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 547 | service\_packages | deleted\_at | TIMESTAMPTZ | YES | NULL |     | Hỗ trợ Soft Delete để bảo toàn dữ liệu lịch sử. |
| 548 | service\_packages | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Dùng cho Optimistic Locking, ngăn chặn ghi đè khi nhiều Admin cùng sửa. |
| 549 | Quản lý Thuê bao (Subscriptions - Fixed Billing) |     | Package |     |     |     |     |
| 550 | tenant\_subscriptions | YSQL | Collection |     |     |     | (Thuê bao hiện hành): Đây là bảng quan trọng nhất, lưu trữ thông tin gói cước mà khách hàng đang sử dụng |
| 551 | tenant\_subscriptions | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và tối ưu Sharding,. |
| 552 | tenant\_subscriptions | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định thuê bao này thuộc về khách hàng nào. |
| 553 | tenant\_subscriptions | package\_id | UUID | NO  |     | FOREIGN KEY tham chiếu service\_packages(\_id) | Tham chiếu gói cước gốc để đối soát và báo cáo doanh thu. |
| 554 | tenant\_subscriptions | price\_amount | NUMERIC(19,4) | NO  | 0   | CHECK (price\_amount >= 0) | Snapshot giá: Lưu giá thực tế tại thời điểm mua để tránh biến động khi gói gốc đổi giá,. |
| 555 | tenant\_subscriptions | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (LENGTH = 3) | Mã tiền tệ theo chuẩn ISO 4217,. |
| 556 | tenant\_subscriptions | granted\_entitlements | JSONB | NO  | {}' |     | Snapshot quyền lợi: Chứa cấu hình chi tiết Features/Limits của từng App. Cho phép ghi đè (Override) khi mua thêm Add-on,. |
| 557 | tenant\_subscriptions | granted\_app\_codes | TEXT\[\] | YES |     | GENERATED ALWAYS AS (...) STORED | Cache mảng: Trích xuất các Key từ JSONB để kiểm tra quyền truy cập App cực nhanh bằng GIN Index,. |
| 558 | tenant\_subscriptions | start\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm bắt đầu có hiệu lực (UTC),. |
| 559 | tenant\_subscriptions | end\_at | TIMESTAMPTZ | YES |     | CHECK (end\_at > start\_at) | Thời điểm hết hạn. NULL nếu là gói vĩnh viễn,. |
| 560 | tenant\_subscriptions | status | VARCHAR(20) | NO  | ACTIVE' | CHECK (IN ('ACTIVE', 'EXPIRED', 'CANCELLED', 'PAST\_DUE')) | Trạng thái của thuê bao,. |
| 561 | tenant\_subscriptions | version | BIGINT | NO  | 1   |     | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời khi có nhiều giao dịch. |
| 562 | tenant\_subscriptions | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (Audit). |
| 563 | tenant\_subscriptions | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 564 | tenant\_subscriptions | deleted\_at | TIMESTAMPTZ | YES |     |     | Hỗ trợ Soft Delete để khôi phục dữ liệu khi cần,. |
| 565 | subscription\_invoices | YSQL | Collection |     |     |     | (Hóa đơn thuê bao): Lưu trữ lịch sử hóa đơn, số tiền, trạng thái thanh toán và mã tiền tệ (ISO 4217) |
| 566 | subscription\_invoices | \_id | UUID | NO  |     | PRIMARY KEY | Định danh hóa đơn chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 567 | subscription\_invoices | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định hóa đơn thuộc về khách hàng nào. Cần thiết để sharding/filtering. |
| 568 | subscription\_invoices | partner\_id | UUID | YES | NULL | REFERENCES tenants(\_id) | ID đối tác phân phối (nếu có) phục vụ đối soát công nợ đa tầng \[Lịch sử\]. |
| 569 | subscription\_invoices | subscription\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết hóa đơn với gói thuê bao cụ thể của khách hàng. |
| 570 | subscription\_invoices | invoice\_number | VARCHAR(50) | NO  |     | UNIQUE | Mã hóa đơn nghiệp vụ (VD: INV-2024-0001) để đối soát với kế toán. |
| 571 | subscription\_invoices | amount | NUMERIC(19,4) | NO  | 0   | CHECK (amount >= 0) | Tổng số tiền cần thanh toán. Độ chính xác 4 số lẻ. |
| 572 | subscription\_invoices | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ ISO 4217 (VND, USD,...). |
| 573 | subscription\_invoices | status | VARCHAR(20) | NO  | OPEN' | CHECK (IN ('DRAFT', 'OPEN', 'PAID', 'VOID', 'UNCOLLECTIBLE')) | Trạng thái hóa đơn: Nháp, Đang mở, Đã trả, Hủy, Nợ xấu. |
| 574 | subscription\_invoices | billing\_period\_start | TIMESTAMPTZ | NO  |     |     | Ngày bắt đầu chu kỳ tính tiền (UTC). |
| 575 | subscription\_invoices | billing\_period\_end | TIMESTAMPTZ | NO  |     | CHECK (end > start) | Ngày kết thúc chu kỳ tính tiền (UTC). |
| 576 | subscription\_invoices | due\_date | TIMESTAMPTZ | NO  |     |     | Hạn chót thanh toán. |
| 577 | subscription\_invoices | paid\_at | TIMESTAMPTZ | YES |     |     | Thời điểm thực tế khách hàng thanh toán thành công. |
| 578 | subscription\_invoices | price\_adjustments | JSONB | NO  | \[\]' |     | Lưu chi tiết giảm giá, chiết khấu để minh bạch hóa đơn. |
| 579 | subscription\_invoices | metadata | JSONB | NO  | {}' |     | Lưu thông tin bổ sung tùy linh hoạt (VD: ghi chú, thông tin Gateway). |
| 580 | subscription\_invoices | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Dùng cho Optimistic Locking chống ghi đè dữ liệu. |
| 581 | subscription\_invoices | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo hóa đơn. |
| 582 | subscription\_invoices | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 583 | subscription\_invoices | deleted\_at | TIMESTAMPTZ | YES |     |     | Hỗ trợ Soft Delete để xóa mềm. |
| 584 | subscription\_orders | YSQL | Collection |     |     |     | (Lệnh mua gói): Ghi lại các lệnh thực hiện mua hoặc nâng cấp gói cước từ phía Tenant. |
| 585 | subscription\_orders | \_id | UUID | NO  |     | PRIMARY KEY | Định danh đơn hàng chuẩn UUID v7. |
| 586 | subscription\_orders | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định đơn hàng thuộc về khách hàng nào. |
| 587 | subscription\_orders | package\_id | UUID | NO  |     | FOREIGN KEY tham chiếu service\_packages(\_id) | Gói cước mà khách hàng đang đặt mua. |
| 588 | subscription\_orders | order\_number | VARCHAR(50) | NO  |     | UNIQUE | Mã đơn hàng nghiệp vụ (VD: ORD-2024-1029) để đối soát. |
| 589 | subscription\_orders | total\_amount | NUMERIC(19,4) | NO  | 0   | CHECK (total\_amount >= 0) | Tổng số tiền đơn hàng. Chính xác 4 số lẻ. |
| 590 | subscription\_orders | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (length = 3) | Mã tiền tệ ISO 4217 (VND, USD...). |
| 591 | subscription\_orders | status | VARCHAR(20) | NO  | PENDING' | CHECK (IN ('PENDING', 'PAID', 'CANCELLED', 'FAILED')) | Trạng thái đơn hàng. |
| 592 | subscription\_orders | payment\_method | VARCHAR(30) | YES |     |     | Phương thức: CREDIT\_CARD, BANK\_TRANSFER, WALLET. |
| 593 | subscription\_orders | package\_snapshot | JSONB | NO  | {}' |     | Snapshot: Lưu cấu hình gói (giá, quyền hạn) tại thời điểm đặt hàng. |
| 594 | subscription\_orders | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking chống ghi đè dữ liệu. |
| 595 | subscription\_orders | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo đơn hàng (UTC). |
| 596 | subscription\_orders | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 597 | subscription\_orders | deleted\_at | TIMESTAMPTZ | YES |     |     | Hỗ trợ Soft Delete. |
| 598 | usage\_events | ClickHouse | Collection |     |     |     | Lưu nhật ký thô về mọi hành động tiêu dùng tài nguyên của Tenant (ví dụ: số lần gọi API, dung lượng bandwidth). Dữ liệu ở đây mang tính chất Append-only và có khối lượng cực lớn. |
| 599 | usage\_events | \_id | UUID | NO  |     | Khóa chính logic (UUID v7). | Định danh duy nhất cho sự kiện, sinh từ ứng dụng. |
| 600 | usage\_events | tenant\_id | UUID | NO  |     | Thành phần của Sorting Key. | Xác định sự kiện thuộc về khách hàng nào. |
| 601 | usage\_events | subscription\_id | UUID | NO  |     | Dùng để đối soát với YugabyteDB. | Liên kết trực tiếp với gói thuê bao hiện hành của khách. |
| 602 | usage\_events | app\_code | String | NO  |     | Thành phần của Sorting Key. | Mã ứng dụng phát sinh tiêu dùng (VD: 'LMS', 'CRM'). |
| 603 | usage\_events | event\_type | Enum8 / String | NO  |     | VD: 'EMAIL\_SENT', 'FILE\_UPLOAD'. | Loại hành động tiêu dùng để áp giá. |
| 604 | usage\_events | quantity | Decimal128(4) | NO  | 0   | Chính xác 4 số lẻ. | Số lượng tiêu dùng thực tế (VD: 1.5 GB, 100 tin nhắn). |
| 605 | usage\_events | unit | String | NO  |     | VD: 'GB', 'UNIT', 'REQ' | Đơn vị tính của lượng tiêu dùng. |
| 606 | usage\_events | metadata | String | NO  | {}' | Lưu dưới dạng chuỗi JSON. | Chứa thông tin bổ sung tùy biến (IP, UserID, Device). |
| 607 | usage\_events | data\_region | String | NO  | DEFAULT' | Phục vụ luật Data Residency. | Vùng dữ liệu vật lý phát sinh sự kiện. |
| 608 | usage\_events | timestamp | DateTime64(3) | NO  | now() | Độ chính xác mili-giây (UTC). | Thời điểm chính xác sự kiện xảy ra. |
| 609 | tenant\_usages | YSQL | Collection |     |     |     | Dữ liệu tổng hợp từ ClickHouse sau khi qua các Job xử lý định kỳ. Bảng này tách biệt việc ghi log tải cao (ClickHouse) và việc tính tiền chính xác (YugabyteDB), giúp hệ thống xuất hóa đơn không bị chậm. |
| 610 | tenant\_usages | \_id | UUID | NO  |     | PRIMARY KEY | Định danh chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian và sharding,. |
| 611 | tenant\_usages | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định dữ liệu tiêu dùng thuộc về khách hàng nào,. |
| 612 | tenant\_usages | subscription\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết với gói thuê bao cụ thể để áp giá Metering,. |
| 613 | tenant\_usages | usage\_period\_start | TIMESTAMPTZ | NO  |     |     | Bắt đầu chu kỳ tổng hợp dữ liệu (UTC),. |
| 614 | tenant\_usages | usage\_period\_end | TIMESTAMPTZ | NO  |     | CHECK (usage\_period\_end > usage\_period\_start) | Kết thúc chu kỳ tổng hợp dữ liệu (UTC). |
| 615 | tenant\_usages | metrics\_data | JSONB | NO  | {}' |     | Chứa các chỉ số tiêu dùng (VD: {"emails\_sent": 150, "storage\_gb": 10}),. |
| 616 | tenant\_usages | status | VARCHAR(20) | NO  | PENDING' | CHECK (status IN ('PENDING', 'BILLED', 'VOID')) | Trạng thái tính tiền: Chờ xử lý, Đã xuất hóa đơn, Hủy bỏ,. |
| 617 | tenant\_usages | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm hệ thống ghi nhận bản ghi tổng hợp. |
| 618 | tenant\_usages | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 619 | tenant\_wallets | YSQL | Collection |     |     |     | (Ví tiền của Tenant): Quản lý số dư tiền nạp trước (Prepaid) của khách hàng để trừ dần theo mô hình FinOps,. |
| 620 | tenant\_wallets | \_id | UUID | NO  |     | PRIMARY KEY | Định danh ví duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 621 | tenant\_wallets | tenant\_id | UUID | NO  |     | UNIQUE, FOREIGN KEY tham chiếu tenants(\_id) | Mỗi khách hàng (Tenant) chỉ sở hữu duy nhất một ví chính. |
| 622 | tenant\_wallets | balance | NUMERIC(19, 4) | NO  | 0   | CHECK (balance >= 0) | Số dư khả dụng. Sử dụng NUMERIC(19, 4) để chính xác tuyệt đối 4 số lẻ. |
| 623 | tenant\_wallets | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ theo chuẩn ISO 4217 (VND, USD,...). |
| 624 | tenant\_wallets | is\_frozen | BOOLEAN | NO  | FALSE |     | Nếu TRUE, ví bị đóng băng (không cho phép thanh toán) do nghi ngờ gian lận. |
| 625 | tenant\_wallets | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu tài chính đồng thời. |
| 626 | tenant\_wallets | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm khởi tạo ví (chuẩn UTC). |
| 627 | tenant\_wallets | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật số dư gần nhất. |
| 628 | wallet\_transactions | YSQL | Collection |     |     |     | (Giao dịch ví): Nhật ký bất biến (Immutable) ghi lại mọi biến động nạp, trừ hoặc hoàn tiền trong ví,. |
| 629 | wallet\_transactions | \_id | UUID | NO  |     | PRIMARY KEY | Định danh giao dịch duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian,. |
| 630 | wallet\_transactions | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định giao dịch thuộc về khách hàng nào để Sharding/Filtering,. |
| 631 | wallet\_transactions | wallet\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenant\_wallets(\_id) | Liên kết trực tiếp với ví thực hiện biến động. |
| 632 | wallet\_transactions | type | VARCHAR(30) | NO  |     | CHECK (type IN ('DEPOSIT', 'USAGE\_DEDUCT', 'REFUND', 'BONUS')) | Loại giao dịch: Nạp tiền, Trừ phí sử dụng, Hoàn tiền, Tặng thưởng,. |
| 633 | wallet\_transactions | amount | NUMERIC(19, 4) | NO  |     | CHECK (amount <> 0) | Số tiền biến động. Dùng NUMERIC(19, 4) để chính xác tuyệt đối,. |
| 634 | wallet\_transactions | balance\_after | NUMERIC(19, 4) | NO  |     | CHECK (balance\_after >= 0) | Snapshot số dư: Số dư ví ngay sau khi thực hiện giao dịch này để đối soát. |
| 635 | wallet\_transactions | reference\_id | UUID | YES |     |     | Liên kết tới hóa đơn (invoices) hoặc đơn hàng (orders) phát sinh giao dịch. |
| 636 | wallet\_transactions | description | TEXT | YES |     |     | Mô tả chi tiết nội dung giao dịch (VD: "Trừ phí gửi 5000 email"). |
| 637 | wallet\_transactions | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm phát sinh giao dịch chuẩn UTC,. |
| 638 | license\_allocations | YSQL | Collection |     |     |     | (Phân bổ giấy phép): Quản lý số lượng "ghế" (seats) hoặc giấy phép đã mua so với số lượng đã gán thực tế cho nhân viên,. |
| 639 | license\_allocations | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 640 | license\_allocations | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định hạn ngạch thuộc về khách hàng nào. |
| 641 | license\_allocations | subscription\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết trực tiếp với gói thuê bao hoặc hóa đơn đã mua. |
| 642 | license\_allocations | license\_type | VARCHAR(30) | NO  | BILLABLE' | CHECK (IN ('BILLABLE', 'GUEST', 'READ\_ONLY')) | Loại giấy phép: Tính phí, Khách, hoặc Chỉ đọc. |
| 643 | license\_allocations | purchased\_quantity | INTEGER | NO  | 0   | CHECK (>= 0) | Tổng số lượng "ghế" khách hàng đã thanh toán. |
| 644 | license\_allocations | assigned\_quantity | INTEGER | NO  | 0   | CHECK (assigned\_quantity <= purchased\_quantity) | Số lượng thực tế đã gán cho người dùng. Không được vượt quá số mua. |
| 645 | license\_allocations | status | VARCHAR(20) | NO  | ACTIVE' | CHECK (IN ('ACTIVE', 'EXPIRED', 'SUSPENDED')) | Trạng thái của hạn ngạch giấy phép. |
| 646 | license\_allocations | expires\_at | TIMESTAMPTZ | YES |     |     | Thời điểm hết hạn của giấy phép này (thường khớp với gói cước). |
| 647 | license\_allocations | version | BIGINT | NO  | 1   |     | Optimistic Locking để ngăn chặn gán quyền đồng thời gây vượt hạn ngạch. |
| 648 | license\_allocations | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC). |
| 649 | license\_allocations | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 650 | price\_adjustments | YSQL | Collection |     |     |     | (Điều chỉnh giá): Lưu trữ các thông tin chiết khấu hoặc giảm giá tùy chỉnh cho từng hóa đơn để đảm bảo tính minh bạch. |
| 651 | price\_adjustments | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 652 | price\_adjustments | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định khoản điều chỉnh này thuộc về khách hàng nào. |
| 653 | price\_adjustments | subscription\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenant\_subscriptions(\_id) | Liên kết với một thuê bao cụ thể của khách hàng. |
| 654 | price\_adjustments | invoice\_id | UUID | YES |     | FOREIGN KEY tham chiếu subscription\_invoices(\_id) | Liên kết với hóa đơn cụ thể (nếu điều chỉnh theo từng kỳ thanh toán). |
| 655 | price\_adjustments | type | VARCHAR(20) | NO  |     | CHECK (type IN ('DISCOUNT', 'SURCHARGE', 'TAX', 'REBATE')) | Loại điều chỉnh: Giảm giá, phụ phí, thuế, hoặc hoàn tiền. |
| 656 | price\_adjustments | amount | NUMERIC(19,4) | NO  | 0   | CHECK (amount >= 0) | Giá trị tuyệt đối của khoản điều chỉnh. |
| 657 | price\_adjustments | currency\_code | VARCHAR(3) | NO  | VND' | CHECK (length(currency\_code) = 3) | Mã tiền tệ ISO 4217. |
| 658 | price\_adjustments | reason | TEXT | NO  |     | CHECK (length(reason) > 0) | Lý do điều chỉnh (VD: "Giảm giá khách hàng thân thiết", "Phí quá hạn"). |
| 659 | price\_adjustments | source | VARCHAR(30) | NO  | MANUAL' |     | Nguồn gốc: MANUAL (Admin nhập), COUPON, AUTOMATIC\_POLICY. |
| 660 | price\_adjustments | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking. |
| 661 | price\_adjustments | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC). |
| 662 | price\_adjustments | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 663 | saas\_business\_reports | ClickHouse | Collection |     |     |     | Báo cáo doanh thu: Các bảng tổng hợp phục vụ việc truy vấn báo cáo doanh thu theo năm hoặc xu hướng khách hàng với tốc độ mili-giây,. |
| 664 | saas\_business\_reports | \_id | UUID | NO  |     | Khóa chính logic (UUID v7) | Định danh duy nhất cho bản ghi báo cáo. |
| 665 | saas\_business\_reports | partner\_id | Nullable(UUID) | YES | NULL |     | ID của đối tác phân phối (nếu báo cáo thuộc một kênh cụ thể) \[Lịch sử trò chuyện\]. |
| 666 | saas\_business\_reports | report\_date | Date32 | NO  |     | Thành phần của Sorting Key | Ngày tham chiếu của dữ liệu báo cáo (YYYY-MM-DD),. |
| 667 | saas\_business\_reports | revenue\_category | Enum8 | NO  |     | NEW' = 1, 'RENEWAL' = 2, 'UPGRADE' = 3, 'ADD\_ON' = 4, 'COMMISSION' = 5 | Phân loại doanh thu để nén dữ liệu cực tốt,. |
| 668 | saas\_business\_reports | total\_revenue | Decimal128(4) | NO  | 0   | Chính xác tuyệt đối 4 số lẻ | Tổng doanh thu hệ thống của hạng mục đó trong ngày,. |
| 669 | saas\_business\_reports | currency\_code | FixedString(3) | NO  | VND' | Chuẩn ISO 4217 | Mã tiền tệ (VND, USD,...),. |
| 670 | saas\_business\_reports | tenant\_count | UInt32 | NO  | 0   |     | Số lượng khách hàng đóng góp vào doanh thu này. |
| 671 | saas\_business\_reports | details\_json | String | NO  | {}' | Dữ liệu dạng JSON String | Chi tiết doanh thu theo từng gói (Pro, Enterprise,...),. |
| 672 | saas\_business\_reports | created\_at | DateTime64(3) | NO  | now() | Độ chính xác mili-giây | Thời điểm hệ thống sinh báo cáo (UTC),. |
| 673 | Nhóm Core Logic Hệ thống |     | Package |     |     |     |     |
| 674 | tenant\_encryption\_keys | YSQL | Collection |     |     |     | Lưu trữ các khóa mã hóa dữ liệu (DEK) riêng biệt cho từng Tenant. Bảng này hỗ trợ tính năng bảo mật cao cấp như Crypto-shredding (xóa vĩnh viễn dữ liệu bằng cách hủy khóa) |
| 675 | tenant\_encryption\_keys | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7. |
| 676 | tenant\_encryption\_keys | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định khóa thuộc về khách hàng nào. |
| 677 | tenant\_encryption\_keys | encrypted\_data\_key | BYTEA | NO  |     |     | Khóa DEK đã được mã hóa bởi Master Key (KEK). Lưu dạng nhị phân để bảo mật cao nhất. |
| 678 | tenant\_encryption\_keys | key\_version | INTEGER | NO  | 1   | CHECK (key\_version >= 1) | Phiên bản của khóa để hỗ trợ xoay vòng khóa (Rotation). |
| 679 | tenant\_encryption\_keys | status | VARCHAR(20) | NO  | ACTIVE' | CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')) | Trạng thái: Nếu là REVOKED, dữ liệu coi như bị xóa vĩnh viễn (Crypto-shredding). |
| 680 | tenant\_encryption\_keys | algorithm | VARCHAR(50) | NO  | AES-256-GCM' |     | Thuật toán mã hóa được sử dụng. |
| 681 | tenant\_encryption\_keys | rotation\_at | TIMESTAMPTZ | YES |     |     | Thời điểm dự kiến cần xoay vòng khóa tiếp theo. |
| 682 | tenant\_encryption\_keys | version | BIGINT | NO  | 1   |     | Optimistic Locking để ngăn chặn cập nhật khóa đồng thời. |
| 683 | tenant\_encryption\_keys | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo khóa (UTC). |
| 684 | tenant\_encryption\_keys | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 685 | tenant\_i18n\_overrides | YSQL | Collection |     |     |     | Cho phép khách hàng ghi đè các thuật ngữ mặc định của hệ thống để phù hợp với đặc thù ngành nghề (ví dụ: đổi "Nhân viên" thành "Bác sĩ" hoặc "Giáo viên"). |
| 686 | tenant\_i18n\_overrides | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất bản ghi (UUID v7), hỗ trợ sắp xếp theo thời gian. |
| 687 | tenant\_i18n\_overrides | tenant\_id | UUID | NO  |     | FOREIGN KEY tham chiếu tenants(\_id) | Xác định bản ghi thuộc về khách hàng nào. |
| 688 | tenant\_i18n\_overrides | locale | VARCHAR(10) | NO  | vi-VN' | CHECK (LENGTH(locale) >= 2) | Mã ngôn ngữ/định dạng (VD: 'en-US', 'vi-VN'). |
| 689 | tenant\_i18n\_overrides | translation\_key | VARCHAR(255) | NO  |     | CHECK (LENGTH(translation\_key) > 0) | Khóa thuật ngữ gốc của hệ thống (VD: 'common.employee'). |
| 690 | tenant\_i18n\_overrides | custom\_value | TEXT | NO  |     | CHECK (LENGTH(custom\_value) > 0) | Giá trị đã được khách hàng đổi tên. |
| 691 | tenant\_i18n\_overrides | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| 692 | tenant\_i18n\_overrides | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo bản ghi (UTC). |
| 693 | tenant\_i18n\_overrides | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cuối cùng. |
| 694 | tenant\_i18n\_overrides | created\_by | UUID | YES |     |     | ID người dùng thực hiện tạo bản ghi. |
| 695 | system\_jobs | YSQL | Collection |     |     |     | Quản lý hàng đợi các tác vụ nền (Background Jobs) như xuất báo cáo Excel, gửi email hàng loạt hoặc tính toán lương, giúp hệ thống không bị quá tải khi xử lý request. |
| 696 | system\_jobs | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7,. |
| 697 | system\_jobs | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Xác định công việc thuộc về khách hàng nào để tính phí hoặc giới hạn. |
| 698 | system\_jobs | job\_type | VARCHAR(50) | NO  |     | CHECK (length > 0) | Loại công việc (VD: EXPORT\_EXCEL, CALCULATE\_PAYROLL). |
| 699 | system\_jobs | payload | JSONB | NO  | {}' |     | Chứa toàn bộ tham số đầu vào của công việc. |
| 700 | system\_jobs | status | VARCHAR(20) | NO  | PENDING' | CHECK IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED') | Trạng thái vòng đời của công việc. |
| 701 | system\_jobs | scheduled\_at | TIMESTAMPTZ | NO  | now() | Lưu chuẩn UTC | Thời điểm dự kiến thực hiện (hỗ trợ hẹn giờ chạy sau). |
| 702 | system\_jobs | started\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm bắt đầu thực thi thực tế. |
| 703 | system\_jobs | finished\_at | TIMESTAMPTZ | YES | NULL |     | Thời điểm hoàn thành hoặc thất bại. |
| 704 | system\_jobs | retry\_count | INT | NO  | 0   | CHECK (retry\_count >= 0) | Số lần đã thử lại khi gặp lỗi. |
| 705 | system\_jobs | max\_retries | INT | NO  | 3   | CHECK (max\_retries >= 0) | Số lần thử lại tối đa cho phép. |
| 706 | system\_jobs | last\_error | TEXT | YES | NULL |     | Lưu vết nội dung lỗi cuối cùng để debug. |
| 707 | system\_jobs | created\_by | UUID | YES | NULL | FK tham chiếu users(\_id) | ID người dùng đã kích hoạt tác vụ này. |
| 708 | system\_jobs | version | BIGINT | NO  | 1   |     | Hỗ trợ Optimistic Locking tránh xử lý trùng. |
| 709 | feature\_flags | YSQL | Collection |     |     |     | Cho phép bật/tắt các tính năng mới cho từng nhóm khách hàng cụ thể mà không cần triển khai lại mã nguồn (Deploy code). |
| 710 | feature\_flags | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất bản ghi theo chuẩn UUID v7,. |
| 711 | feature\_flags | flag\_key | VARCHAR(50) | NO  |     | UNIQUE, CHECK (length > 0) | Mã kỹ thuật của tính năng (VD: ENABLE\_AI\_WRITING, BETA\_UI),. |
| 712 | feature\_flags | description | TEXT | YES | NULL |     | Mô tả chi tiết mục đích của cờ tính năng này. |
| 713 | feature\_flags | is\_global\_enabled | BOOLEAN | NO  | FALSE |     | Nếu là TRUE, tính năng được bật cho toàn bộ hệ thống bất kể các quy tắc khác,. |
| 714 | feature\_flags | rules | JSONB | NO  | {}' |     | Chứa logic bật tắt như: tỷ lệ phần trăm (percentage), danh sách tenant được phép (allowed\_tenants), hoặc vùng bị loại trừ (excluded\_regions),. |
| 715 | feature\_flags | version | BIGINT | NO  | 1   |     | Hỗ trợ Optimistic Locking để ngăn chặn việc ghi đè cấu hình khi nhiều admin cùng chỉnh sửa. |
| 716 | feature\_flags | created\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm tạo cờ (theo chuẩn UTC),. |
| 717 | feature\_flags | updated\_at | TIMESTAMPTZ | NO  | now() |     | Thời điểm cập nhật cấu hình cuối cùng. |
| 718 | tenant\_rate\_limits | YSQL | Collection |     |     |     | (Giới hạn tần suất) Bảng này được thiết kế để bảo vệ hệ thống khỏi việc bị quá tải do một khách hàng sử dụng tài nguyên quá mức |
| 719 | tenant\_rate\_limits | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7. |
| 720 | tenant\_rate\_limits | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Nếu NULL, đây là cấu hình mặc định toàn sàn (Global Default). |
| 721 | tenant\_rate\_limits | api\_group | VARCHAR(50) | NO  |     | CHECK (length > 0) | Nhóm API bị giới hạn (VD: 'REPORTING\_API', 'CORE\_API'). |
| 722 | tenant\_rate\_limits | limit\_count | INT | NO  |     | CHECK (limit\_count > 0) | Số lượng request tối đa được phép. |
| 723 | tenant\_rate\_limits | window\_seconds | INT | NO  | 60  | CHECK (window\_seconds > 0) | Khung thời gian áp dụng giới hạn (tính bằng giây). |
| 724 | tenant\_rate\_limits | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái kích hoạt của quy tắc. |
| 725 | tenant\_rate\_limits | description | TEXT | YES | NULL |     | Ghi chú về mục đích của giới hạn này. |
| 726 | tenant\_rate\_limits | created\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm tạo bản ghi. |
| 727 | tenant\_rate\_limits | updated\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| 728 | tenant\_rate\_limits | version | BIGINT | NO  | 1   |     | Hỗ trợ Optimistic Locking khi cập nhật cấu hình. |
| 729 | tenant\_app\_configs | MongoDB | Collection |     |     |     | chứa các cấu hình vận hành (như màu sắc, logo, ngôn ngữ) thay vì dữ liệu nghiệp vụ |
| 730 | tenant\_app\_configs | \_id | String (UUID) | NO  | \-  | Khóa chính, định dạng UUID v7, | Định danh duy nhất, hỗ trợ sắp xếp theo thời gian,. |
| 731 | tenant\_app\_configs | tenant\_id | String (UUID) | NO  | \-  | Shard Key, tham chiếu tenants.\_id, | Xác định cấu hình thuộc về khách hàng nào. |
| 732 | tenant\_app\_configs | app\_code | String | NO  | \-  | Duy nhất theo cặp (tenant\_id, app\_code) | Mã định danh ứng dụng (VD: 'HRM', 'CRM', 'POS'). |
| 733 | tenant\_app\_configs | configs | Object (BSON) | NO  | {}  | Schema-less (Linh hoạt) | Chứa các cài đặt động như theme\_color, workflow\_steps, logo,. |
| 734 | tenant\_app\_configs | version | Int64 | NO  | 1   | version >= 1 | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| 735 | tenant\_app\_configs | created\_at | Date (ISODate) | NO  | now() | Chuẩn UTC, | Thời điểm tạo bản ghi. |
| 736 | tenant\_app\_configs | updated\_at | Date (ISODate) | NO  | now() | Chuẩn UTC, | Thời điểm cập nhật cuối cùng. |
| 737 | system\_announcements | YSQL | Collection |     |     |     | Dùng để gửi thông báo bảo trì, cảnh báo nợ cước hoặc khuyến mãi đến hàng triệu người dùng mà không làm quá tải cơ sở dữ liệu |
| 738 | system\_announcements | \_id | UUID | NO  | \-  | PRIMARY KEY | Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian. |
| 739 | system\_announcements | titles | JSONB | NO  | {}' | Cấu trúc đa ngôn ngữ | Lưu tiêu đề theo locale (VD: {"vi": "Bảo trì", "en": "Maintenance"}) để hỗ trợ đa ngôn ngữ. |
| 740 | system\_announcements | contents | JSONB | NO  | {}' | Cấu trúc đa ngôn ngữ | Lưu nội dung chi tiết theo locale. Hỗ trợ định dạng Markdown hoặc HTML. |
| 741 | system\_announcements | type | VARCHAR(20) | NO  | INFO' | CHECK (type IN ('INFO', 'WARNING', 'CRITICAL', 'PROMOTION')) | Phân loại thông báo: Tin tức, Cảnh báo, Bảo trì hoặc Khuyến mãi. |
| 742 | system\_announcements | target\_regions | TEXT\[\] | YES | NULL |     | Mảng chứa danh sách vùng địa lý nhận tin (VD: \['VN\_NORTH'\]). Nếu NULL là toàn cầu. |
| 743 | system\_announcements | target\_plans | TEXT\[\] | YES | NULL |     | Mảng chứa mã gói cước nhận tin (VD: \['FREE\_TIER'\]). Nếu NULL là mọi gói. |
| 744 | system\_announcements | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái hiển thị của thông báo. |
| 745 | system\_announcements | is\_local\_time | BOOLEAN | NO  | FALSE |     | Nếu TRUE, thời gian hiển thị sẽ được cộng dời theo múi giờ (timezone) của từng Tenant. |
| 746 | system\_announcements | start\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm bắt đầu hiển thị thông báo. |
| 747 | system\_announcements | end\_at | TIMESTAMPTZ | YES | NULL | CHECK (end\_at > start\_at) | Thời điểm kết thúc hiển thị. |
| 748 | system\_announcements | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Optimistic Locking ngăn chặn xung đột khi nhiều Admin cùng sửa cấu hình. |
| 749 | system\_announcements | created\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm tạo bản ghi. |
| 750 | system\_announcements | updated\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| 751 | user\_announcement\_reads | YSQL | Collection |     |     |     | lưu trữ trạng thái "đã đọc" của từng người dùng |
| 752 | user\_announcement\_reads | \_id | UUID | NO  |     | PRIMARY KEY | Định danh duy nhất theo chuẩn UUID v7. |
| 753 | user\_announcement\_reads | tenant\_id | UUID | NO  |     | FK tham chiếu tenants(\_id) | Xác định bản ghi thuộc về khách hàng nào để đảm bảo tính cô lập dữ liệu (SaaS Isolation). |
| 754 | user\_announcement\_reads | user\_id | UUID | NO  |     | FK tham chiếu users(\_id) | Người dùng đã thực hiện hành động đọc thông báo. |
| 755 | user\_announcement\_reads | announcement\_id | UUID | NO  |     | FK tham chiếu system\_announcements(\_id) | ID của thông báo đã được đọc. |
| 756 | user\_announcement\_reads | read\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm chính xác người dùng nhấn xem thông báo. |
| 757 | user\_announcement\_reads | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để tránh ghi đè dữ liệu. |
| 758 | notification\_templates | YSQL | Collection |     |     |     | Mẫu thông báo, hỗ trợ đa kênh như Email (HTML), SMS (Text), Slack (JSON) |
| 759 | notification\_templates | \_id | UUID | NO  | \-  | PRIMARY KEY (UUID v7) | Định danh duy nhất cho mẫu. |
| 760 | notification\_templates | tenant\_id | UUID | YES | NULL | FK tham chiếu tenants(\_id) | Nếu NULL là mẫu chung của hệ thống, nếu có ID là mẫu riêng của khách hàng. |
| 761 | notification\_templates | code | VARCHAR(100) | NO  | \-  | Duy nhất theo (tenant\_id, code) | Mã gợi nhớ (VD: 'NEW\_INVOICE', 'PASSWORD\_RESET'). |
| 762 | notification\_templates | name | TEXT | NO  | \-  | CHECK (length > 0) | Tên hiển thị của mẫu để quản trị viên dễ nhận biết. |
| 763 | notification\_templates | subject\_templates | JSONB | NO  | {}' | Cấu trúc đa ngôn ngữ | Lưu tiêu đề (cho Email/Push) theo locale: {"vi": "...", "en": "..."}. |
| 764 | notification\_templates | body\_templates | JSONB | NO  | {}' | Hỗ trợ HTML/Liquid | Lưu nội dung chi tiết theo locale và kênh (Email, Slack). |
| 765 | notification\_templates | sms\_template | TEXT | YES | NULL |     | Nội dung tin nhắn SMS (thường là text thuần). |
| 766 | notification\_templates | required\_variables | TEXT\[\] | YES | {}' |     | Danh sách các biến cần truyền vào (VD: \['user\_name', 'otp\_code'\]). |
| 767 | notification\_templates | is\_active | BOOLEAN | NO  | TRUE |     | Trạng thái cho phép sử dụng mẫu này. |
| 768 | notification\_templates | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking. |
| 769 | notification\_templates | created\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm tạo mẫu. |
| 770 | notification\_templates | updated\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm cập nhật cuối cùng. |
| 771 | user\_notification\_settings | YSQL | Collection |     |     |     | Người dùng có thể cấu hình để chọn nhận tin qua Email, SMS hay Push cho từng loại thông báo cụ thể (ví dụ: chỉ nhận cảnh báo bảo mật qua SMS, còn tin khuyến mãi chỉ nhận qua App) |
| 772 | user\_notification\_settings | \_id | UUID | NO  | \-  | PRIMARY KEY (UUID v7) | Định danh duy nhất cho bản ghi cấu hình. |
| 773 | user\_notification\_settings | tenant\_id | UUID | NO  | \-  | FK tham chiếu tenants(\_id) | Xác định cấu hình thuộc về tổ chức nào để đảm bảo cô lập dữ liệu SaaS. |
| 774 | user\_notification\_settings | user\_id | UUID | NO  | \-  | FK tham chiếu users(\_id) | Người dùng sở hữu cấu hình nhận thông báo này. |
| 775 | user\_notification\_settings | notification\_code | VARCHAR(50) | NO  | \-  | Tham chiếu notification\_templates(code) | Mã loại thông báo (VD: 'NEW\_INVOICE', 'TASK\_ASSIGNED'). |
| 776 | user\_notification\_settings | channels | JSONB | NO  | {}' | Cấu trúc: {"email": bool, "sms": bool, ...} | Lưu trạng thái bật/tắt của từng kênh nhận tin dưới dạng JSON linh hoạt. |
| 777 | user\_notification\_settings | version | BIGINT | NO  | 1   | CHECK (version >= 1) | Hỗ trợ Optimistic Locking để ngăn chặn ghi đè dữ liệu đồng thời. |
| 778 | user\_notification\_settings | updated\_at | TIMESTAMPTZ | NO  | now() | Chuẩn UTC | Thời điểm cập nhật cấu hình gần nhất phục vụ Audit. |
applications	YSQL	Collection				định nghĩa các đơn vị phần mềm kỹ thuật cụ thể (ví dụ: App Tuyển dụng, App Chấm công) trước khi được đóng gói thành các gói cước thương mại (service_packages)
applications	_id	UUID	NO	-	PRIMARY KEY	Định danh duy nhất chuẩn UUID v7, hỗ trợ sắp xếp theo thời gian.
applications	code	VARCHAR(50)	NO	-	UNIQUE, CHECK (code ~ '^[A-Z0-9_]+$')	Mã định danh kỹ thuật (VD: HRM_RECRUIT). Chỉ chứa chữ hoa, số và gạch dưới.
applications	name	VARCHAR(255)	NO	-	CHECK (LENGTH(name) > 0)	Tên hiển thị của ứng dụng trên giao diện.
applications	description	TEXT	YES	NULL	-	Mô tả chi tiết về chức năng kỹ thuật của ứng dụng.
applications	is_active	BOOLEAN	NO	TRUE	-	Trạng thái bật/tắt ứng dụng trên toàn hệ thống.
applications	created_at	TIMESTAMPTZ	NO	now()	Chuẩn UTC	Thời điểm tạo bản ghi ứng dụng.
applications	updated_at	TIMESTAMPTZ	NO	now()	CHECK (updated_at >= created_at)	Thời điểm cập nhật dữ liệu gần nhất.
applications	deleted_at	TIMESTAMPTZ	YES	NULL	-	Thời điểm xóa mềm (Soft Delete) để bảo toàn dữ liệu lịch sử.
applications	version	BIGINT	NO	1	CHECK (version >= 1)	Cơ chế Optimistic Locking, ngăn chặn ghi đè dữ liệu đồng thời.
traffic_logs 	ClickHouse	Collection				Bảng này ghi nhận mọi yêu cầu (Request) đi vào hệ thống, bao gồm các thông số về băng thông, độ trễ và ngữ cảnh khách hàng
traffic_logs 	_id	UUID	NO	-	Khóa chính logic (UUID v7)	Định danh duy nhất cho mỗi bản ghi log.
traffic_logs 	tenant_id	UUID	NO	-	Thành phần Sorting Key	Định danh tổ chức sở hữu lưu lượng để cô lập dữ liệu khách hàng.
traffic_logs 	user_id	Nullable(UUID)	YES	NULL	-	ID người dùng thực hiện request (nếu đã xác thực).
traffic_logs 	app_code	String	NO	-	Thành phần Sorting Key	Mã ứng dụng nhận request (VD: HRM, CRM, POS).
traffic_logs 	method	Enum8(...)	NO	-	GET=1, POST=2, ...	Phương thức HTTP, dùng Enum để tối ưu nén.
traffic_logs 	domain	String	NO	-	-	Tên miền yêu cầu (VD: hr.abc.com).
traffic_logs 	path	String	NO	-	-	Đường dẫn cụ thể (VD: /api/v1/employees).
traffic_logs 	status_code	Int16	NO	-	-	Mã trạng thái HTTP (VD: 200, 404, 500).
traffic_logs 	latency_ms	Int32	NO	-	-	Độ trễ xử lý của hệ thống tính bằng mili-giây.
traffic_logs 	request_size	Int64	NO	0	Byte	Dung lượng request đầu vào để tính Bandwidth.
traffic_logs 	response_size	Int64	NO	0	Byte	Dung lượng response đầu ra để tính Bandwidth.
traffic_logs 	ip_address	IPv6	NO	-	-	Địa chỉ IP người dùng (Hỗ trợ cả IPv4 và IPv6).
traffic_logs 	user_agent	String	YES	NULL	-	Thông tin thiết bị và trình duyệt truy cập.
traffic_logs 	data_region	String	NO	DEFAULT'	-	Vùng vật lý phát sinh traffic phục vụ tuân thủ dữ liệu.
traffic_logs 	timestamp	DateTime64(3)	NO	now()	UTC	Thời điểm chính xác request xảy ra (độ chính xác ms).
