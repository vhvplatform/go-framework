|     | A   | B   | C   | D   | E   | F   | G   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1   | Bảng | Tên trường (Field) | Kiểu dữ liệu | Null? | Mặc định (Default) | Ràng buộc (Constraints) & Logic Kiểm tra | Mô tả |
|     |     |     |     |     |     |     |     |
| 2   | CORE & IDENTITY (HẠ TẦNG & ĐỊNH DANH) |     | Package |     |     |     |     |
| 3   | Nhóm Định danh và Tổ chức Cốt lõi (Core Foundation) |     | Package |     |     |     | Nhóm này quản lý danh tính con người và cấu trúc pháp nhân của khách hàng |
| 4   | tenants | YSQL | Collection |     |     |     | Lưu thông tin khách hàng, định danh (\_id, code), ràng buộc vùng (data\_region) và cấu hình gốc. |
| 24  | users | YSQL | Collection |     |     |     | Lưu trữ thông tin định danh toàn cục của một con người thực (Email, Password Hash, Avatar). Đây là bảng duy nhất chứa thông tin đăng nhập trên toàn sàn. |
| 38  | tenant\_members | YSQL | Collection |     |     |     | Bảng liên kết người dùng với tổ chức. Nó lưu hồ sơ nhân viên, mã nhân viên, chức danh và trạng thái làm việc tại một công ty cụ thể. |
| 51  | Nhóm Cơ cấu và Nhóm (Organization & Structure) |     | Package |     |     |     | Giúp phản ánh cấu trúc thực tế của doanh nghiệp |
| 52  | departments | YSQL | Collection |     |     |     | Quản lý cây phòng ban theo phân cấp (Hierarchy) sử dụng phương pháp Materialized Path để truy vấn nhanh |
| 65  | department\_members | YSQL | Collection |     |     |     | Phân bổ nhân sự vào các phòng ban (quan hệ N-N) |
| 74  | user\_groups | YSQL | Collection |     |     |     | Quản lý các nhóm làm việc ngang hàng, dự án hoặc squad. Có thể thiết lập nhóm tĩnh hoặc nhóm động (Dynamic Groups) theo quy tắc |
| 87  | group\_members | YSQL | Collection |     |     |     | Danh sách thành viên trong các nhóm tĩnh |
| 96  | locations | YSQL | Collection |     |     |     | Quản lý các địa điểm vật lý, văn phòng hoặc chi nhánh của Tenant |
| 109 | Nhóm Xác thực và Bảo mật (Authentication & Security) |     | Package |     |     |     | Đáp ứng các tiêu chuẩn bảo mật hiện đại như MFA và Passwordless |
| 110 | user\_linked\_identities | YSQL | Collection |     |     |     | Quản lý đa phương thức đăng nhập (Password, Google, GitHub, Microsoft) liên kết với một tài khoản người dùng. |
| 119 | user\_sessions | YSQL | Collection |     |     |     | Quản lý phiên làm việc thực tế, thiết bị, IP và hỗ trợ cơ chế xoay vòng token (Rotation). |
| 134 | user\_mfa\_methods | YSQL | Collection |     |     |     | Lưu trữ các phương thức xác thực đa yếu tố (TOTP, SMS, Email). |
| 143 | user\_webauthn\_credentials | YSQL | Collection |     |     |     | Hỗ trợ đăng nhập bằng vân tay, FaceID hoặc khóa vật lý (Passkeys/FIDO2). |
| 153 | user\_backup\_codes | YSQL | Collection |     |     |     | Mã khôi phục khi người dùng mất thiết bị MFA. |
| 160 | tenant\_sso\_configs | YSQL | Collection |     |     |     | Cấu hình đăng nhập doanh nghiệp (SAML/OIDC) để tích hợp với Azure AD, Okta. |
| 173 | auth\_verification\_codes | YSQL | Collection |     |     |     | Mã OTP hoặc Magic Link ngắn hạn để xác thực email hoặc đổi mật khẩu. |
| 183 | personal\_access\_tokens | YSQL | Collection |     |     |     | Token dành cho lập trình viên hoặc scripts tích hợp hệ thống. |
| 196 | auth\_logs | ClickHouse | Collection |     |     |     |     |
| 208 | Nhóm Phân quyền (Authorization - IAM) |     | Package |     |     |     | Kiểm soát quyền truy cập từ mức tính năng đến mức dữ liệu |
| 209 | roles | YSQL | Collection |     |     |     | Định nghĩa các vai trò (VD: Admin, Editor) và danh sách mã quyền đi kèm. |
| 219 | permissions | YSQL | Collection |     |     |     | Danh mục các hành động kỹ thuật do lập trình viên định nghĩa cứng trong code. |
| 226 | user\_roles | YSQL | Collection |     |     |     | Gán vai trò cho thành viên, hỗ trợ phạm vi dữ liệu (scope\_values) như theo phòng ban hoặc khu vực. |
| 235 | relationship\_tuples | YSQL | Collection |     |     |     | Mô hình phân quyền dựa trên quan hệ (ReBAC - Google Zanzibar) cho các kịch bản chia sẻ tài nguyên phức tạp. |
| 244 | access\_control\_lists | YSQL | Collection |     |     |     | Kiểm soát truy cập chi tiết cho từng tài nguyên cụ thể (VD: Folder, Document). |
| 254 | Nhóm Quản trị và Tuân thủ (Governance & Compliance) |     | Package |     |     |     | Đáp ứng các yêu cầu của khách hàng Enterprise lớn |
| 255 | tenant\_domains | YSQL | Collection |     |     |     | Xác thực tên miền sở hữu (VD: @fpt.com) để tự động quản lý thành viên và thực thi SSO. |
| 265 | tenant\_invitations | YSQL | Collection |     |     |     | Quản lý quy trình mời và gia nhập của người dùng mới. |
| 276 | access\_reviews | YSQL | Collection |     |     |     | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| 287 | access\_review\_items | YSQL | Collection |     |     |     | Quản lý các đợt rà soát quyền hạn định kỳ theo chuẩn ISO/SOC2. |
| 298 | scim\_directories | YSQL | Collection |     |     |     | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| 307 | scim\_mappings | YSQL | Collection |     |     |     | Tự động hóa việc đồng bộ hóa người dùng từ các hệ thống IdP bên ngoài như Azure AD. |
| 316 | legal\_documents | YSQL | Collection |     |     |     | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| 326 | user\_consents | YSQL | Collection |     |     |     | Lưu trữ các điều khoản sử dụng và bằng chứng chấp thuận của người dùng. |
| 334 | security\_audit\_logs | ClickHouse | Collection |     |     |     | (Nhật ký an ninh lõi): Tập trung vào các sự kiện an ninh cấp độ hệ thống như: đăng nhập thất bại, gán vai trò (role) cho người dùng, tạo API Key, hoặc thay đổi chính sách bảo mật |
| 347 | user\_delegations | YSQL | Collection |     |     |     | Cho phép ủy quyền hành động (Impersonation) có thời hạn và có kiểm soát. |
| 358 | Nhóm Quản lý Truy cập (Access Management) |     | Package |     |     |     |     |
| 359 | api\_keys | YSQL | Collection |     |     |     |     |
| 372 | service\_accounts | YSQL | Collection |     |     |     |     |
| 384 | user\_devices | YSQL | Collection |     |     |     |     |
| 394 | tenant\_app\_routes | YSQL | Collection |     |     |     |     |
| 406 | tenant\_rate\_limits | YSQL | Collection |     |     |     |     |
| 417 | oauth\_clients | YSQL | Collection |     |     |     |     |
| 429 | webhooks | YSQL | Collection |     |     |     |     |
| 440 | api\_usage\_logs | ClickHouse | Collection |     |     |     |     |
| 452 | webhook\_delivery\_logs | ClickHouse | Collection |     |     |     |     |
| 465 | audit\_logs | ClickHouse | Collection |     |     |     | Nhật ký kiểm tra hệ thống. Lưu vết toàn bộ các hành động thay đổi dữ liệu của người dùng trên hệ thống. Đặc biệt, bảng này trong mô hình Enterprise sẽ bao gồm trường impersonator\_id để ghi lại định danh của nhân viên hỗ trợ nếu họ đang sử dụng tính năng "Impersonation" (giả danh khách hàng) để xử lý sự cố |
| 478 | outbox\_events | YSQL | Collection |     |     |     |     |
| 488 | user\_registration\_logs | ClickHouse | Collection |     |     |     |     |
| 495 | Nhóm Billing & FinOps |     | Package |     |     |     |     |
| 496 | Danh mục Sản phẩm & Gói dịch vụ |     | Package |     |     |     | Đây là nơi quy định các "nguyên liệu" đầu vào của hệ thống trước khi đóng gói thành các gói cước thương mại. |
| 549 | Quản lý Thuê bao (Subscriptions - Fixed Billing) |     | Package |     |     |     |     |
| 673 | Nhóm Core Logic Hệ thống |     | Package |     |     |     |     |
| 674 | tenant\_encryption\_keys | YSQL | Collection |     |     |     | Lưu trữ các khóa mã hóa dữ liệu (DEK) riêng biệt cho từng Tenant. Bảng này hỗ trợ tính năng bảo mật cao cấp như Crypto-shredding (xóa vĩnh viễn dữ liệu bằng cách hủy khóa) |
| 685 | tenant\_i18n\_overrides | YSQL | Collection |     |     |     | Cho phép khách hàng ghi đè các thuật ngữ mặc định của hệ thống để phù hợp với đặc thù ngành nghề (ví dụ: đổi "Nhân viên" thành "Bác sĩ" hoặc "Giáo viên"). |
| 695 | system\_jobs | YSQL | Collection |     |     |     | Quản lý hàng đợi các tác vụ nền (Background Jobs) như xuất báo cáo Excel, gửi email hàng loạt hoặc tính toán lương, giúp hệ thống không bị quá tải khi xử lý request. |
| 709 | feature\_flags | YSQL | Collection |     |     |     | Cho phép bật/tắt các tính năng mới cho từng nhóm khách hàng cụ thể mà không cần triển khai lại mã nguồn (Deploy code). |
| 718 | tenant\_rate\_limits | YSQL | Collection |     |     |     | (Giới hạn tần suất) Bảng này được thiết kế để bảo vệ hệ thống khỏi việc bị quá tải do một khách hàng sử dụng tài nguyên quá mức |
| 729 | tenant\_app\_configs | MongoDB | Collection |     |     |     | chứa các cấu hình vận hành (như màu sắc, logo, ngôn ngữ) thay vì dữ liệu nghiệp vụ |
| 737 | system\_announcements | YSQL | Collection |     |     |     | Dùng để gửi thông báo bảo trì, cảnh báo nợ cước hoặc khuyến mãi đến hàng triệu người dùng mà không làm quá tải cơ sở dữ liệu |
| 751 | user\_announcement\_reads | YSQL | Collection |     |     |     | lưu trữ trạng thái "đã đọc" của từng người dùng |
| 758 | notification\_templates | YSQL | Collection |     |     |     | Mẫu thông báo, hỗ trợ đa kênh như Email (HTML), SMS (Text), Slack (JSON) |
| 771 | user\_notification\_settings | YSQL | Collection |     |     |     | Người dùng có thể cấu hình để chọn nhận tin qua Email, SMS hay Push cho từng loại thông báo cụ thể (ví dụ: chỉ nhận cảnh báo bảo mật qua SMS, còn tin khuyến mãi chỉ nhận qua App) |
