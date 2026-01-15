# Xác định tenant và application

**Dựa trên các nguồn tài liệu và lịch sử trao đổi về kiến trúc hệ thống SaaS B2B quy mô lớn, dưới đây là tổng hợp toàn diện các quy tắc xử lý Domain và URL để xác định Tenant và Application.Quy trình này dựa trên nguyên tắc "Bản đồ định tuyến trung tâm" (Centralized Routing Map) sử dụng bảng tenant\_app\_routes làm nguồn sự thật (Source of Truth) và Redis làm bộ nhớ đệm tốc độ cao.**

**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**1\. Nguyên tắc cốt lõi \(Core Principles\)**
**1\. Một địa chỉ \- Một đích đến: Mọi cặp \(Domain \+ Path Prefix\) chỉ được phép trỏ về duy nhất một Tenant và một Application cụ thể\. Không được phép có sự trùng lặp \(Global Uniqueness\)\.**
**2\. Tách biệt Định danh và Định tuyến: Bảng tenants chỉ lưu thông tin định danh\. Việc tenant đó chạy ở domain nào\, folder nào được quản lý riêng biệt tại bảng tenant\_app\_routes\.**
**3\. Ưu tiên tốc độ: Việc tra cứu định tuyến phải diễn ra dưới 1ms\. Do đó\, logic này không query trực tiếp vào bảng tenants mà query vào tenant\_app\_routes \(có Index tối ưu\) hoặc Redis Cache\.**
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**2\. Thiết kế dữ liệu định tuyến \(tenant\_app\_routes\)**
**Bảng này là "trái tim" của cơ chế định tuyến, được lưu tại YugabyteDB để đảm bảo tính nhất quán (ACID).**

| **Trường** | **Vai trò & Logic** | **Ví dụ** |
| ------ | --------------- | ----- |
| **domain** | **Tên miền truy cập (Host).** | **fpt.saas.com hoặc hr.fpt.com** |
| **path\_prefix** | **Đường dẫn để phân biệt App/Tenant trên cùng domain. Mặc định là /.** | **/ hoặc /hrm** |
| **tenant\_id** | **KẾT QUẢ 1: Xác định khách hàng nào.** | **uuid-fpt** |
| **app\_code** | **KẾT QUẢ 2: Xác định ứng dụng nào.** | **HRM\_APP** |
| **is\_custom\_domain** | **TRUE: Domain riêng khách mua.\<br>FALSE: Subdomain hệ thống.** | **TRUE** |

**Chỉ mục chiến lược (Covering Index): Để Gateway lấy thông tin mà không cần đọc bảng gốc, sử dụng Index bao phủ:**
\*\*CREATE UNIQUE INDEX idx\_routes\_fast\_lookup \*\*
\*\*ON tenant\_app\_routes (domain, path\_prefix) \*\*
**INCLUDE (tenant\_id, app\_code, is\_custom\_domain);**

<br>
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**

<br>
**3\. Quy trình xử lý tại API Gateway \(Routing Algorithm\)**
**Khi một request bay vào (ví dụ: https://hr.fpt.com/api/employees), Gateway sẽ thực hiện logic sau:**
**Bước 1: Phân tích URL (Parse)**
**• Host: hr.fpt.com**
**• Path: /api/employees -> Lấy prefix cấp 1 là / (hoặc /api tùy cấu hình, nhưng thường định tuyến dựa trên root path hoặc folder app).**
**Bước 2: Tra cứu (Lookup)**
**Hệ thống thực hiện tra cứu theo thứ tự ưu tiên tốc độ:**
**1\. Lớp 1 \(Redis\): Kiểm tra Key router:domains:\{host\}:\{path\}\. Nếu có \-\> Trả về ngay\.**
**2\. Lớp 2 \(YugabyteDB\): Nếu Cache Miss\, query DB:**
**3\. Lớp 3 \(Cache Write\): Ghi kết quả từ DB vào Redis để lần sau nhanh hơn\.**
**Bước 3: Kiểm tra quyền hạn (Entitlement Check)**
**Sau khi xác định được tenant\_id và app\_code, Gateway kiểm tra bảng tenant\_subscriptions (đã cache hoặc query nhanh) xem Tenant này còn hạn sử dụng App đó không và trạng thái có phải là ACTIVE không**
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**4\. Các kịch bản định tuyến \(Routing Scenarios\)**
**Hệ thống hỗ trợ linh hoạt 4 mô hình định tuyến phổ biến nhất:**
**Kịch bản A: Subdomain (Mỗi Tenant một Subdomain)**
**• URL: fpt.saas.com**
**• Record: Domain=fpt.saas.com, Path=/**
**• Kết quả: Tenant=FPT, App=PORTAL (Trang chủ/Dashboard).**
**Kịch bản B: Path-based (Chung Domain, phân biệt bằng Folder)**
**• URL: saas.com/fpt**
**• Record: Domain=saas.com, Path=/fpt**
**• Kết quả: Tenant=FPT, App=PORTAL.**
**Kịch bản C: Multi-App (Một Tenant dùng nhiều App trên 1 Domain)**
**• URL 1: fpt.saas.com/hrm -> Vào App HRM.**
    **◦ Record: Domain=fpt.saas.com, Path=/hrm -> App=HRM.**
**• URL 2: fpt.saas.com/crm -> Vào App CRM.**
    **◦ Record: Domain=fpt.saas.com, Path=/crm -> App=CRM.**
**Kịch bản D: Custom Domain (Tên miền riêng)**
**• URL: hr.th-group.com**
**• Record: Domain=hr.th-group.com, Path=/**
**• Kết quả: Tenant=TH\_Group, App=HRM.**
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**5\. Xử lý xung đột và Ngoại lệ**
**1\. Xung đột Path:**
    **◦ Hệ thống phải chặn việc Tenant đăng ký các path\_prefix trùng với các đường dẫn hệ thống (Reserved Paths) như: /api, /admin, /login, /static, /health.**
    **◦ Ràng buộc UNIQUE(domain, path\_prefix) trong DB đảm bảo Tenant A không thể đăng ký lại đường dẫn mà Tenant B đang dùng.**
**2\. Khớp tiền tố dài nhất \(Longest Prefix Match\):**
    **◦ Nếu có 2 rule: saas.com/fpt và saas.com/fpt/hrm.**
    **◦ Khi user vào saas.com/fpt/hrm/users, Gateway cần chọn rule dài hơn (/fpt/hrm) để định tuyến chính xác vào App HRM thay vì vào Portal (/fpt).**
**3\. Thay đổi đường dẫn \(Migration\):**
    **◦ Nếu đổi prefix từ /hrm sang /hrm2, cần cập nhật DB và xóa Cache Redis.**
    **◦ Nên hỗ trợ cơ chế Redirect 301 tại Gateway để không làm gãy bookmark của người dùng cũ.**
**Tóm tắt**
**Quy tắc xác định Tenant và Application là: Dựa vào cặp khóa duy nhất (Domain + Path Prefix) để tra cứu trong bảng tenant\_app\_routes, sau đó đối chiếu với tenant\_subscriptions để xác thực quyền truy cập.**
**Dựa trên thiết kế của bảng tenant\_app\_routes và logic định tuyến (Routing) trong hệ thống SaaS đa khách hàng được mô tả ở các nguồn tài liệu, việc xác định tenant (khách hàng) và application (ứng dụng) từ URL được thực hiện thông qua việc so khớp cặp giá trị Domain (Tên miền) và Path Prefix (Tiền tố đường dẫn).**
**Dưới đây là các trường hợp (Scenarios) cụ thể để hệ thống xác định danh tính và đích đến từ URL:**
**Nguyên lý cốt lõi**
**Hệ thống sử dụng bảng tenant\_app\_routes làm bản đồ định tuyến. Khi có một request, API Gateway sẽ tách URL thành Host và Path, sau đó truy vấn bảng này (hoặc Redis cache) để tìm ra tenant\_id và app\_code tương ứng,.**
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**Các trường hợp xác định cụ thể**
**Trường hợp 1: Sử dụng Subdomain của hệ thống (Mô hình mặc định)**
**Đây là trường hợp phổ biến nhất khi khách hàng chưa cấu hình tên miền riêng. Tenant được xác định qua slug trên subdomain, và App được xác định qua đường dẫn hoặc mặc định.**
**• URL: https://fpt.saas.com/**
    **◦ Phân tích: Domain = fpt.saas.com, Path = /**
    **◦ Kết quả:**
        **▪ Tenant: Công ty FPT (được map từ slug fpt).**
        **▪ App: PORTAL hoặc DASHBOARD (Ứng dụng mặc định khi vào trang chủ).**
    **◦ Dữ liệu bảng Routes: domain='fpt.saas.com', path\_prefix='/' -> app\_code='DASHBOARD'.**
**• URL: https://fpt.saas.com/hrm**
    **◦ Phân tích: Domain = fpt.saas.com, Path = /hrm**
    **◦ Kết quả:**
        **▪ Tenant: Công ty FPT.**
        **▪ App: HRM\_APP (Ứng dụng Quản trị nhân sự).**
    **◦ Dữ liệu bảng Routes: domain='fpt.saas.com', path\_prefix='/hrm' -> app\_code='HRM\_APP'.**
**Trường hợp 2: Sử dụng Custom Domain chuyên biệt (App-specific Domain)**
**Khách hàng cấu hình một tên miền riêng (VD: hr.congty.com) để trỏ thẳng vào một ứng dụng cụ thể, giúp nhân viên truy cập nhanh mà không qua Portal chung.**
**• URL: https://hr.fpt-corp.com/**
    **◦ Phân tích: Domain = hr.fpt-corp.com, Path = /**
    **◦ Kết quả:**
        **▪ Tenant: Công ty FPT (Hệ thống tra cứu thấy domain này thuộc về FPT).**
        **▪ App: HRM\_APP (Do domain này được cấu hình cứng cho App HRM).**
    **◦ Dữ liệu bảng Routes: domain='hr.fpt-corp.com', path\_prefix='/' -> app\_code='HRM\_APP'.**
**Trường hợp 3: Sử dụng Custom Domain cho Portal (Portal Domain)**
**Khách hàng dùng tên miền riêng cho trang chủ, sau đó truy cập các ứng dụng con qua đường dẫn (Path).**
**• URL: https://work.fpt-corp.com/crm**
    **◦ Phân tích: Domain = work.fpt-corp.com, Path = /crm**
    **◦ Kết quả:**
        **▪ Tenant: Công ty FPT.**
        **▪ App: CRM\_APP.**
    **◦ Dữ liệu bảng Routes: domain='work.fpt-corp.com', path\_prefix='/crm' -> app\_code='CRM\_APP'.**
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**
**Bảng tóm tắt logic định tuyến**
**Dựa vào dữ liệu mẫu trong nguồn, ta có bảng tổng hợp cách hệ thống "phiên dịch" URL:**

| **URL Khách truy cập** | **Domain (Host)** | **Path Prefix** | **Tenant ID (Kết quả)** | **App Code (Kết quả)** | **Loại Domain** |
| ------------------ | ------------- | ----------- | ------------------- | ------------------ | ----------- |
| **abc.saas.com** | **abc.saas.com** | **/** | **uuid\_abc** | **DASHBOARD** | **Subdomain hệ thống** |
| **abc.saas.com/hrm** | **abc.saas.com** | **/hrm** | **uuid\_abc** | **HRM\_APP** | **Subdomain + Path** |
| **hr.congty-abc.com** | **hr.congty-abc.com** | **/** | **uuid\_abc** | **HRM\_APP** | **Custom Domain** |

**Quy trình xử lý kỹ thuật (Flow)**
**Theo nguồn và, khi một request bay vào:**
**1\. Phân tích: Gateway tách lấy Host và Path từ URL\.**
**2\. Tra cứu \(Lookup\): Hệ thống tìm kiếm trong bảng tenant\_app\_routes \(thường được cache trên Redis\) với điều kiện khớp domain và path\_prefix\.**
**3\. Xác định \(Identify\): Nếu tìm thấy bản ghi\, hệ thống lấy được tenant\_id và app\_code\.**
**4\. Kiểm tra quyền \(Entitlement\): Sau khi biết Tenant và App\, hệ thống sẽ tiếp tục kiểm tra bảng tenant\_subscriptions xem Tenant đó có quyền sử dụng App này hay không \(Active/Expired\) trước khi cho phép truy cập\.**

# Điều hướng tính năng

**Dựa trên kiến trúc hệ thống SaaS đã thiết kế và các nguồn dữ liệu, sau khi hệ thống đã xác định được Tenant ID (Khách hàng) và App Code (Ứng dụng) thông qua bảng tenant\_app\_routes [Source 156, 456, 1985], việc điều hướng tiếp theo (Sub-routing) sẽ được phân loại dựa trên cấu trúc của phần đường dẫn còn lại (Suffix Path).**
**Dưới đây là mô tả chi tiết các trường hợp xác định điều hướng:**

## 1\. Điều hướng API \(Data Endpoints\)$3

**Đây là trường hợp phổ biến nhất khi Frontend (SPA/Mobile) giao tiếp với Backend để lấy dữ liệu.**
**• Nhận diện: Đường dẫn bắt đầu bằng tiền tố định danh API, thường là /api. Đây là từ khóa hệ thống phải "giữ chỗ" (reserved keyword) [Source 97].**
**• Cấu trúc URL: [Root\_URL]/api/[version]/[resource]/...**
**• Quy trình xử lý:**
    **1\. Rate Limiting: Gateway kiểm tra bảng tenant\_rate\_limits để đảm bảo Tenant không gọi quá giới hạn cho phép \(VD: 1000 req/phút\) \[Source 1603\, 1634\]\.**
    **2\. Authentication: Kiểm tra Header Authorization \(Bearer Token hoặc API Key\)\.**
        **▪ Nếu dùng API Key: Tra cứu bảng api\_keys [Source 398, 1195].**
        **▪ Nếu dùng Token: Tra cứu bảng user\_sessions [Source 183, 996].**
    **3\. Authorization: Kiểm tra quyền truy cập tài nguyên dựa trên bảng permissions và access\_control\_lists \[Source 230\, 1060\]\.**
    **4\. Routing nội bộ: Chuyển tiếp request đến Microservice tương ứng \(VD: Service HRM\, Service Billing\)\.**

## 2\. Điều hướng Tài nguyên Tĩnh \(Static Assets\)$3

**Dành cho các file hình ảnh, CSS, JavaScript, Font chữ phục vụ giao diện.**
**• Nhận diện: Đường dẫn bắt đầu bằng các tiền tố như /static, /assets, /public, /images.**
**• Cấu trúc URL: [Root\_URL]/static/[version]/[filename]**
**• Quy trình xử lý:**
    **◦ Bypass Application Logic: Gateway (Nginx/Cloudflare) sẽ bỏ qua các bước kiểm tra quyền hạn phức tạp (như RBAC) để tối ưu tốc độ.**
    **◦ Cache: Trả về file trực tiếp từ bộ nhớ đệm hoặc Object Storage (S3/MinIO) [Source 493].**
    **◦ Lưu ý: Các file riêng tư của Tenant (như Hợp đồng, Avatar) không dùng đường dẫn này mà phải qua API có xác thực (/api/v1/files/...) [Source 494].**

## 3\. Điều hướng System & Webhooks \(Integration\)$3

**Dành cho các luồng tích hợp hệ thống hoặc bên thứ 3 gọi lại (Callback).**
**• Nhận diện: Đường dẫn bắt đầu bằng /webhooks, /health, /metrics.**
**• Cấu trúc URL: [Root\_URL]/webhooks/[provider\_name]/[event\_type]**
**• Quy trình xử lý:**
    **1\. Tra cứu Webhook: Hệ thống kiểm tra bảng webhooks để xác thực secret\_key hoặc chữ ký số\, đảm bảo request đến từ nguồn tin cậy \(như Stripe\, Slack\) \[Source 1277\, 1650\]\.**
    **2\. Ghi Log: Ghi nhận vào bảng webhook\_delivery\_logs \(tại ClickHouse\) để phục vụ đối soát \[Source 1291\, 1666\]\.**
    **3\. Xử lý Async: Đẩy sự kiện vào hàng đợi \(Queue\) để xử lý sau\, tránh làm nghẽn Gateway\.**

## 4\. Điều hướng Giao diện \(Frontend Pages / Client\-side Routing\)$3

**Dành cho người dùng cuối truy cập vào các trang chức năng trên trình duyệt.**
**• Nhận diện: Tất cả các đường dẫn không thuộc 3 nhóm trên.**
**• Cấu trúc URL: [Root\_URL]/[module]/[action] (Ví dụ: /dashboard, /employees).**
**• Quy trình xử lý:**
    **1\. Trả về SPA: Server trả về file index\.html \(Single Page Application\)\.**
    **2\. Client\-side Routing: Trình duyệt \(React/Vue Router\) sẽ phân tích URL để render component tương ứng\.**
    **3\. Feature Flag Check: Frontend gọi API kiểm tra bảng feature\_flags \(thường cache qua Redis\) để xem User/Tenant hiện tại có được phép thấy trang này không \(Ví dụ: Ẩn trang "AI Writing" nếu Tenant chưa mua gói Pro\) \[Source 1591\, 2025\]\.**

## 5\. Điều hướng Tài nguyên Động \(Dynamic Slugs\)$3

**Trường hợp Tenant có các trang nội dung tùy chỉnh như bài viết, sản phẩm, landing page.**
**• Nhận diện: Không khớp với các từ khóa hệ thống (api, static, admin...).**
**• Cấu trúc URL: [Root\_URL]/[slug] hoặc [Root\_URL]/p/[product-slug].**
**• Quy trình xử lý:**
    **1\. Tra cứu Slug: Hệ thống tra cứu trong các bảng nghiệp vụ \(như saas\_products hoặc bảng CMS riêng của Tenant\) để tìm nội dung tương ứng với slug\.**
    **2\. Xử lý xung đột: Do slug do người dùng đặt\, hệ thống phải đảm bảo nó không trùng với các "Reserved Keywords" \(từ khóa dành riêng\) đã được định nghĩa trong bảng reserved\_slugs \(hoặc logic code\) \[Source 97\]\.**
**Bảng tóm tắt quy tắc điều hướng (Routing Priority)**
**Để đảm bảo không xung đột, Gateway sẽ thực hiện so khớp theo thứ tự ưu tiên sau:**

| **Thứ tự** | **Loại** | **Tiền tố (Prefix Match)** | **Xử lý bởi** | **Ghi chú** |
| ------ | ---- | ---------------------- | --------- | ------- |
| **1** | **System** | **/health, /metrics** | **Infra Monitor** | **Bỏ qua Auth** |
| **2** | **Static** | **/static, /assets, /public, /images** | **CDN / Nginx** | **Cache mạnh** |
| **3** | **API** | **/api** | **API Gateway** | **Check Rate Limit, AuthN, AuthZ** |
| **4** | **Webhooks** | **/webhooks** | **Backend Service** | **Verify Signature** |
| **5** | **App** | **/\* (Còn lại)** | **Frontend (SPA)** | **Trả về index.html** |

**Việc phân tách rõ ràng này giúp hệ thống của bạn đạt chuẩn "World-class SaaS" về mặt cấu trúc, dễ dàng mở rộng và bảo trì [Source 1, 2].**

# Chi tiết về xử lý static

**Dựa trên kiến trúc hệ thống SaaS Enterprise đã thiết kế và các nguyên tắc quản lý tài nguyên trong chuỗi hội thoại, việc phân biệt 4 loại đường dẫn tĩnh (/static, /assets, /public, /images) không chỉ là vấn đề đặt tên, mà là sự phân chia về Nguồn gốc dữ liệu (Origin), Vòng đời (Lifecycle) và Chiến lược Caching.**
**Dưới đây là sự phân biệt chi tiết:**
**1\. /static: Tài nguyên Hệ thống \(Build Artifacts\)**
**Đây là các file được sinh ra từ quá trình Build/Compile mã nguồn Frontend (React/Vue/Angular).**
**• Nguồn gốc: Do lập trình viên tạo ra, được đóng gói khi Deploy.**
**• Thành phần: File .js (Logic code), .css (Giao diện), .map (Source map).**
**• Đặc điểm:**
    **◦ Tên file thường chứa mã Hash (ví dụ: main.a1b2c3.js) để đảm bảo tính duy nhất cho từng phiên bản.**
    **◦ Cache: Vĩnh viễn (Immutable). Trình duyệt có thể cache các file này 1 năm vì nếu code thay đổi, tên file sẽ thay đổi [Source 493].**
**• Xử lý: Nginx/CDN phục vụ trực tiếp, tuyệt đối không đi qua Backend API.**
**2\. /assets: Tài nguyên Giao diện \(UI Resources\)**
**Đây là các file nguyên liệu được dùng để xây dựng nên giao diện, nhưng không phải là code thực thi.**
**• Nguồn gốc: Do Designer/Developer đưa vào Source Code.**
**• Thành phần: Font chữ (.woff2), Icon hệ thống (SVG), Ảnh nền mặc định (Background patterns), File ngôn ngữ (.json).**
**• Đặc điểm:**
    **◦ Thường không bị Hash tên file (ví dụ: logo-white.svg, font-inter.woff2).**
    **◦ Cache: Dài hạn (Long-term), nhưng cần cơ chế ETag để kiểm tra nếu file có cập nhật.**
**• Lưu ý: Trong bảng reserved\_slugs (Từ khóa cấm), /assets phải được ưu tiên bảo vệ để tránh Tenant đặt trùng tên [Source 97].**
**3\. /public: Tài nguyên Người dùng Công khai \(Public User Content\)**
**Đây là các file do Khách hàng (Tenant/User) tải lên và được cấu hình để ai cũng xem được.**
**• Nguồn gốc: User upload thông qua tính năng "Tải ảnh đại diện", "Tải logo công ty".**
**• Lưu trữ: File vật lý nằm trên S3/MinIO, metadata nằm trong bảng storage\_files với cờ is\_public = TRUE [Source 1139].**
**• Đặc điểm:**
    **◦ URL không đổi nhưng nội dung có thể đổi (ví dụ Tenant đổi logo mới).**
    **◦ Cache: Ngắn hạn hoặc Trung hạn (ví dụ: 1 giờ đến 1 ngày).**
**• Kiến trúc: Request vào /public/tenant-1/logo.png sẽ được Gateway (Nginx) proxy thẳng sang S3 hoặc CDN, không đi qua App Server để giảm tải [Source 493].**
**4\. /images: Tài nguyên Đa phương tiện & Xử lý ảnh \(Media Optimization\)**
**Trong các hệ thống SaaS hiện đại, đường dẫn này thường dành riêng cho việc Xử lý ảnh động (On-the-fly Transformation).**
**• Nguồn gốc: User upload (giống /public), nhưng cần hiển thị ở nhiều kích thước khác nhau (Thumbnail, Mobile, Desktop).**
**• Cấu trúc URL: Thường chứa tham số xử lý.**
    **◦ Ví dụ: /images/resize/w\_200/h\_200/tenants/123/avatar.jpg**
**• Cơ chế:**
    **◦ Hệ thống tích hợp với các Image CDN (như Cloudinary, Imgix) hoặc tự dựng Thumbor [Source 33].**
    **◦ Khi gọi vào /images, hệ thống sẽ cắt/nén ảnh gốc từ S3 rồi trả về, thay vì trả về file gốc nặng nề.**
**• Lưu ý: URL này thường rất dài, do đó trong database (như bảng users), cột chứa URL này phải là kiểu TEXT chứ không được là VARCHAR(255) [Source 34, 35].**

<br>
**\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-**

<br>
**Bảng tổng hợp so sánh**

| **Đường dẫn** | **Bản chất** | **Ai tạo ra?** | **Lưu trữ tại** | **Chiến lược Cache** | **Xử lý bởi** |
| --------- | -------- | ---------- | ----------- | ---------------- | --------- |
| **/static** | **Code đã biên dịch (JS/CSS)** | **Dev / Build Tool** | **Local Server / CDN** | **Vĩnh viễn (Immutable)** | **Nginx / CDN** |
| **/assets** | **Font, Icon, Theme** | **Designer** | **Local Server / CDN** | **ETag / Revalidate** | **Nginx / CDN** |
| **/public** | **Logo, Banner (File gốc)** | **User (Tenant)** | **S3 / MinIO** | **TTL ngắn (Refreshable)** | **Gateway Proxy -> S3** |
| **/images** | **Ảnh đã resize/nén** | **Image Engine** | **S3 (Gốc) -> Cache** | **Cache bản đã xử lý** | **Image CDN / Service** |

**Tác động đến Kiến trúc Database**
**1\. Bảng reserved\_slugs: Bạn BẮT BUỘC phải thêm cả 4 từ khóa này \(static\, assets\, public\, images\) vào danh sách cấm trong bảng reserved\_slugs để ngăn Tenant đặt tên trùng \(ví dụ: fpt\.saas\.com/static sẽ gây lỗi giao diện toàn trang\) \[Source 97\]\.**
**2\. Bảng storage\_files: Chỉ quản lý dữ liệu cho nhóm /public và /images\. Các file thuộc nhóm /static và /assets không nằm trong Database vì chúng là mã nguồn \[Source 1138\]\.**
**3\. Routing: Tại bảng tenant\_app\_routes\, các route bắt đầu bằng 4 tiền tố này sẽ không bao giờ được lưu\, vì chúng được xử lý ở tầng Gateway trước khi chạm vào Database \[Source 152\, 97\]\.**
**So sánh mục đích sử dụng của bảng Features và bảng Configs.**
**Tại sao nên dùng kiểu dữ liệu TEXT thay vì VARCHAR(255)?**
**Hệ thống lưu trữ dữ liệu theo triết lý Polyglot Persistence như thế nào?**
**các loại file khác thì sao?**
**Dựa trên các nguyên tắc thiết kế hệ thống SaaS trong tài liệu, các loại file khác (không phải tài nguyên tĩnh như CSS/JS hay ảnh public) được xếp vào nhóm Tài liệu Nghiệp vụ (Business Documents) và Dữ liệu Tạm thời (System Artifacts).**
**Các loại file này có đặc tính là Riêng tư (Private), Nhạy cảm (Sensitive) hoặc Có vòng đời ngắn. Cách xử lý chúng khác hoàn toàn với /static hay /public.**
**Dưới đây là chiến lược xử lý chi tiết cho các nhóm file này:**
**1\. Tài liệu Nghiệp vụ Riêng tư \(Private Documents\)**
**Đây là các file như: Hợp đồng lao động, Hóa đơn (Invoice), Bảng lương, CMND/CCCD, Bằng cấp.**
**• Nguyên tắc cốt lõi: "Security First". File này tuyệt đối không được truy cập trực tiếp qua đường dẫn công khai (Public URL).**
**• Cơ chế truy cập: Sử dụng Presigned URL (URL có chữ ký tạm thời) [Source 35, 493].**
    **1\. User gọi API \(ví dụ: GET /api/contracts/123/download\)\.**
    **2\. Backend kiểm tra quyền \(User này có phải là nhân viên sở hữu hợp đồng hoặc HR Manager không?\)\.**
    **3\. Nếu hợp lệ\, Backend yêu cầu S3 sinh ra một URL có kèm Signature và Expiration \(ví dụ: hết hạn sau 5 phút\)\.**
    **4\. Backend trả URL này về cho Frontend để tải file\.**
**• Lưu trữ:**
    **◦ Trên S3/MinIO: Đặt trong các Bucket chế độ Private.**
    **◦ Trong Database: Bảng member\_documents hoặc invoices chỉ lưu file\_id tham chiếu đến bảng trung gian storage\_files [Source 295, 359].**
**2\. File Hệ thống sinh ra \(System Generated / Exports\)**
**Đây là các file như: Báo cáo Excel xuất ra từ hệ thống, File sao lưu (Backup), Log nén.**
**• Đặc điểm: File thường nặng, mất thời gian để tạo ra và chỉ cần thiết trong thời gian ngắn.**
**• Quy trình xử lý (Async): Không được xử lý trực tiếp (Synchronous) vì sẽ làm treo trình duyệt [Source 234, 235].**
    **1\. User bấm "Xuất báo cáo"\.**
    **2\. Hệ thống tạo một bản ghi trong bảng system\_jobs với trạng thái PENDING\.**
    **3\. Worker chạy ngầm \(Background Job\) để tính toán và tạo file Excel\.**
    **4\. Worker upload file lên S3 \(thư mục temp/ hoặc exports/\)\.**
    **5\. Hệ thống gửi thông báo \(Notification\) cho User kèm link tải \(Presigned URL\)\.**
**• Vòng đời (Lifecycle): Cấu hình S3 Lifecycle Policy để tự động xóa các file này sau 3-7 ngày để tiết kiệm chi phí.**
**3\. Thiết kế Database quản lý file tập trung \(storage\_files\)**
**Thay vì lưu đường dẫn rải rác, bạn nên dùng bảng storage\_files trong YugabyteDB để quản lý tập trung mọi file "khác" này [Source 359].**

| **Tên trường** | **Kiểu dữ liệu** | **Mô tả & Logic** |
| ---------- | ------------ | ------------- |
| **\_id** | **UUID** | **Khóa chính (UUID v7).** |
| **tenant\_id** | **UUID** | **Tenant sở hữu file (Để tính quota dung lượng).** |
| **object\_key** | **TEXT** | **Đường dẫn vật lý trên S3 (VD: tenants/123/contracts/2024/hd.pdf).** |
| **bucket\_name** | **VARCHAR** | **Tên Bucket chứa file (VD: secure-docs-prod).** |
| **mime\_type** | **VARCHAR** | **Loại file (VD: application/pdf, application/vnd.ms-excel).** |
| **size\_bytes** | **BIGINT** | **Kích thước file (Dùng để tính tiền/giới hạn gói cước).** |
| **is\_public** | **BOOLEAN** | **FALSE (Mặc định cho các loại file này).** |
| **uploader\_id** | **UUID** | **Người tải lên hoặc System (nếu là file export).** |

**4\. Định tuyến \(Routing\) cho các file này**
**Khác với /static hay /images, các file này không có URL cố định. Đường dẫn tải file sẽ là các API Endpoint được bảo vệ:**
**• Hợp đồng: GET /api/v1/members/{id}/documents/{doc\_id}**
**• Hóa đơn: GET /api/v1/billing/invoices/{invoice\_id}/pdf**
**• File Export: GET /api/v1/downloads/{job\_id}**
**5\. Kiểm soát chi phí \(Metering\)**
**Với các loại file này, dung lượng lưu trữ và băng thông tải về thường lớn. Hệ thống cần tích hợp với module Billing [Source 1581, 1813]:**
**1\. Storage: Tổng hợp cột size\_bytes trong bảng storage\_files để tính tổng dung lượng Tenant đang dùng\.**
**2\. Bandwidth: Ghi log sự kiện FILE\_DOWNLOAD vào bảng usage\_events \(ClickHouse\) mỗi khi User tải file để tính phí băng thông nếu gói cước quy định\.**
**Tóm lại:**
**• Ảnh public/Giao diện: Dùng đường dẫn tĩnh (/public, /images), CDN cache mạnh.**
**• Hợp đồng/Hóa đơn/Excel: Dùng đường dẫn API, xác thực quyền nghiêm ngặt, lưu Private trên S3, truy cập qua Presigned URL và quản lý vòng đời chặt chẽ.**
