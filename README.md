# sku02428flutter

Flutter client kế thừa protocol trực tiếp từ `sku02428` + `sku02428wss`.

## Flow

1. App tạo/lưu session UUID + username local.
2. Mở WebSocket và gửi `hello`.
3. Server trả `session_ready` và UID thực tế.
4. Tab Social tìm chính xác username đang online bằng `search_users`.
5. `chat_request` -> peer `chat_accept` / `chat_reject`.
6. Khi nhận `chat_created`, app tự chuyển sang tab Chat.
7. Chat dùng cùng WebSocket cho message/file/reconnect.

## Cấu hình WSS

Không cần sửa source nếu dùng dart-define:

```bash
flutter pub get
flutter run --dart-define=WS_URL=wss://YOUR-WSS-SERVER
```

Android emulator chạy server local trên máy host:

```bash
flutter run --dart-define=WS_URL=ws://10.0.2.2:8080
```

iOS Simulator thường dùng:

```bash
flutter run --dart-define=WS_URL=ws://127.0.0.1:8080
```

Production nên dùng `wss://`.

## Protocol đã implement

Client -> server: `hello`, `search_users`, `chat_request`, `chat_accept`, `chat_reject`, `message`, `file_start`, `file_chunk`, `file_end`, `chat_close`, `end_session`.

Server -> client: `session_ready`, `online_count`, `search_results`, `chat_request`, `chat_request_cancelled`, `chat_request_sent`, `chat_rejected`, `chat_created`, `message`, `file_start/chunk/end/abort`, `peer_status`, `peer_disconnected`, `chat_expired`, `chat_closed`, `error`, `session_ended`.

## Ghi chú

- Search server hiện tại là exact username match, không phải fuzzy search.
- Session/chat là tạm thời theo backend hiện tại; chat mặc định hết hạn theo `CHAT_TTL_MS` của server.
- File tối đa 3.5 MiB theo server. Bản Flutter chọn file và relay qua WSS; file nhận hiện được giữ trong RAM của phiên app.
- Flutter không tạo REST API mới.

## Platform scaffold

Repo ZIP này có source Flutter đầy đủ. Nếu Flutter SDK của bạn yêu cầu regenerate platform files theo version SDK đang dùng, chạy một lần:

```bash
flutter create --platforms=android,ios .
flutter pub get
```

Lệnh này giữ nguyên `lib/` và tạo/cập nhật Android/iOS runner chuẩn theo Flutter SDK trên máy bạn.
