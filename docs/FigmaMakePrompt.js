var prompts = [
	"Prompt 1",
	"Prompt 2",
], currentIdx = 0, startTime = new Date().getTime();

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
		let hasContent = !!inputField.value;
		if(!hasContent){
			setReactInputValue(inputField, prompts[currentIdx]);
		}
		// Kích hoạt sự kiện input để AI nhận diện có văn bản mới
		inputField.dispatchEvent(new Event('input', { bubbles: true }));

		// Gửi prompt sau 1 giây để đảm bảo hệ thống đã nhận văn bản
		setTimeout(() => {
			sendButton.click();
			if(!hasContent) {
				if(currentIdx) {
					let duration = ((new Date()).getTime() - startTime)/1000;
					console.log('Đã chạy được: '+currentIdx+'/'+prompts.length+' prompt, hết '+Math.round(duration)+'s, trung bình '+Math.round(duration/currentIdx)+'s. Để thêm prompts mới dùng lệnh: prompts.push("Lệnh mới"); Để dừng chạy dùng lệnh: prompts = [];');
				}
				currentIdx++;
			}
			// Đợi 10-15 giây để AI xử lý xong trước khi gửi prompt tiếp theo
			setTimeout(sendPrompt, 15000);
		}, 1000);
	}
}
sendPrompt();
