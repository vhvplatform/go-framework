const prompts = [
    "tạo bảng và dữ liệu demo cho bảng auth_logs gắn với các users thật trong db, ở sidebar chính thêm menu Lịch sử truy cập quản lý các lịch sử truy cập lưu vào bảng auth_logs, trang chi tiết tenant thêm menu Lịch sử truy cập liệt kê dữ liệu auth_logs của riêng tenant, trang chi tiết người dùng thêm menu Lịch sử truy cập liệt kê dữ liệu auth_logs của riêng người dùng đó. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng user_roles gắn với các users thật và roles thật trong db, ở trang chi tiết tenant thêm trang Phân quyền liệt kê các người dùng được phân quyền lấy từ user_roles của tenant đó, trong trang chi tiết người dùng thêm menu Phân quyền liệt kê các quyền người dùng đó được phân lấy từ user_roles, cho phép thêm sửa xóa, form thêm sửa cho phép phân quyền đc cho nhiều scope. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng legal_documents, ở sidebar chính thêm menu Điều khoản sử dụng quản lý các điều khoản sử dụng lưu vào bảng legal_documents,cho phép thêm sửa xóa. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng user_consents gắn với các users thật trong db, trong trang chi tiết người dùng thêm menu Điều khoản sử dụng liệt kê các điều khoản sử dụng người dùng đó đã chấp nhận lấy từ user_consents. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng user_delegations gắn với các users thật trong db, ở sidebar chính thêm menu Ủy quyền quản lý các ủy quyền lưu vào bảng user_delegations, trang chi tiết tenant thêm menu Ủy quyền liệt kê dữ liệu user_delegations của riêng tenant, trang chi tiết người dùng thêm menu Ủy quyền liệt kê dữ liệu user_delegations của riêng người dùng đó, cho phép thêm sửa xóa. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng user_devices gắn với các users thật trong db, trang chi tiết người dùng thêm menu Thiết bị liệt kê dữ liệu user_devices của riêng người dùng đó, cho phép thêm sửa xóa. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng tenant_app_routes gắn với các tenant thật trong db, trang chi tiết tenant thêm menu App routes liệt kê dữ liệu tenant_app_routes của riêng tenant, cho phép thêm sửa xóa. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng tenant_rate_limits gắn với các tenant thật, service_packages thật trong db, ở sidebar chính thêm menu Rate limits quản lý các giới hạn tần suất lưu vào bảng tenant_rate_limits,trang chi tiết tenant thêm menu Rate limits liệt kê dữ liệu tenant_rate_limits của riêng tenant, cho phép thêm sửa xóa. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"tạo bảng và dữ liệu demo cho bảng webhooks gắn với các tenant thật trong db, ở sidebar chính thêm menu Webhooks quản lý các webhooks lưu vào bảng webhooks,trang chi tiết tenant thêm menu Webhooks liệt kê dữ liệu webhooks của riêng tenant, cho phép thêm sửa xóa, xem chi tiết. đảm bảo file code không quá 500 dòng, dễ đọc, dễ phát triển về sau, tuân thủ chuẩn Sonar, cần kế thừa code để tránh trùng lặp, tính năng phải dễ sử dụng, viết api đầy đủ logic, lưu dữ liệu thật vào supabase, sau mỗi lần viết doc ngắn gọn thôi",
	"hoàn thiện menu tenants, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết tenant, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Quản lý người dùng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang Chi tiết người dùng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Ứng dụng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Ứng dụng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Thông báo hệ thống, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Vai trò, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Vai trò, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Lịch sử truy cập, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Sản phẩm, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Sản phẩm, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Gói dịch vụ, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Gói dịch vụ, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Đơn hàng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết đơn hàng, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Hóa đơn, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Hóa đơn, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Đăng ký dịch vụ, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện trang chi tiết Đăng ký dịch vụ, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	"hoàn thiện menu Webhooks, đảm bảo đúng với thiết kế CSDL trong docs/DatabaseCommand.md, viết code api Golang tương ứng, viết các tài liệu liên quan tương ứng cho trang Tài liệu Developer: api, bảng dữ liệu, sơ đồ ERD, usecases",
	
];

let currentIdx = 0;

function setReactInputValue(inputField, value) {
    // 1. Tìm setter gốc của React dành cho giá trị textarea/input
    const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
        window.HTMLTextAreaElement.prototype, // Dùng HTMLInputElement nếu là input
        "value"
    ).set;

    // 2. Ép gán giá trị mới thông qua setter gốc
    nativeInputValueSetter.call(inputField, value);

    // 3. Gửi sự kiện 'input' để React nhận diện sự thay đổi và cập nhật state
    const event = new Event('input', { bubbles: true });
    inputField.dispatchEvent(event);
}
function sendPrompt() {
	if (currentIdx >= prompts.length) return;
	
	// Tìm ô nhập liệu của Figma Make (thường là thẻ có contenteditable hoặc textarea)
	const inputField = document.getElementById('code-chat-chat-box-form');
	const sendButton = document.querySelector('[data-testid="code-chat-send-button"]');
	if(!sendButton) {
		setTimeout(sendPrompt, 15000);
		return;
	}
	if (inputField && sendButton) {
		inputField.focus();
		setReactInputValue(inputField, prompts[currentIdx]);

		// Kích hoạt sự kiện input để AI nhận diện có văn bản mới
		inputField.dispatchEvent(new Event('input', { bubbles: true }));

		// Gửi prompt sau 1 giây để đảm bảo hệ thống đã nhận văn bản
		setTimeout(() => {
			sendButton.click();
			currentIdx++;
			// Đợi 10-15 giây để AI xử lý xong trước khi gửi prompt tiếp theo
			setTimeout(sendPrompt, 15000);
		}, 1000);
	}
}
sendPrompt();

