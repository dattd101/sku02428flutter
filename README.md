# sku02428flutter server

WebSocket backend riêng cho app Flutter SKU02428. Project kế thừa protocol của `sku02428wss`, để app Flutter có cùng flow session-only: tạo UID tạm → online → tìm UID → gửi/nhận yêu cầu chat → chat realtime → gửi file → kết thúc session.

## Endpoint

Sau khi deploy Vercel, ví dụ project domain là `https://sku02428flutter.vercel.app`:

- WebSocket: `wss://sku02428flutter.vercel.app/api/ws`
- Health: `https://sku02428flutter.vercel.app/api/health`

App Flutter chỉ cần cấu hình `WS_URL` thành WebSocket endpoint trên.

## Chạy local

Yêu cầu Node.js >= 20.

```bash
npm install
npm run check
npm run dev:local
```

Local WebSocket: `ws://127.0.0.1:8080`
Local health: `http://127.0.0.1:8080/health`

Hoặc test runtime Next/Vercel:

```bash
npm run dev
```

## Deploy Vercel

1. Tạo GitHub repository `sku02428flutter`.
2. Push toàn bộ nội dung thư mục này lên repo.
3. Import repo đó vào Vercel.
4. Framework Preset: Next.js.
5. Deploy.
6. Mở `/api/health` để kiểm tra server.
7. Đổi `WS_URL` trong app Flutter sang `wss://<domain>/api/ws`.

Native Flutter thường không gửi browser Origin, vì vậy mặc định `ALLOWED_ORIGINS` để trống. Nếu đặt biến này, server chỉ nhận đúng các Origin được liệt kê, phân cách bằng dấu phẩy.

## Protocol

Client bắt đầu bằng:

```json
{"type":"hello","sessionId":"<optional UUID>","username":"<optional username>"}
```

Server trả `session_ready` gồm UID/user, số online và các chat còn sống. Các event chính:

- Client → server: `hello`, `search_users`, `chat_request`, `chat_accept`, `chat_reject`, `message`, `file_start`, `file_chunk`, `file_end`, `file_cancel`, `chat_close`, `end_session`, `pong`.
- Server → client: `session_ready`, `online_count`, `search_results`, `chat_request`, `chat_request_sent`, `chat_rejected`, `chat_created`, `message`, `file_start`, `file_chunk`, `file_end`, `file_abort`, `peer_status`, `peer_disconnected`, `chat_closed`, `chat_expired`, `session_ended`, `error`.

### Search UID

```json
{"type":"search_users","query":"user_1790560867839"}
```

### Request chat

```json
{"type":"chat_request","targetUserId":"<id từ search_results>"}
```

Người nhận accept:

```json
{"type":"chat_accept","requestId":"<request id>"}
```

Hai phía nhận `chat_created`. Từ đây dùng `chat.id` để gửi message.

### Message

```json
{"type":"message","chatId":"<chat id>","clientMessageId":"<uuid>","text":"Xin chào"}
```

## Đặc tính hiện tại

- Không database, không lưu nội dung chat trên server.
- UID/session nằm trong memory của instance server.
- Chat mặc định hết hạn sau 60 phút.
- Có grace period reconnect 8 giây.
- Tin nhắn tối đa 2.000 ký tự.
- File tối đa 3.5 MB; tối đa 30 file/chat; relay theo chunk base64.
- Có rate limit cơ bản và heartbeat.

> Lưu ý production: vì state đang nằm trong RAM, kiến trúc này phù hợp với mô hình temp/session chat hiện tại. Nếu cần session bền vững qua cold start, scale nhiều instance hoặc deploy lại server, cần chuyển presence/session/chat metadata sang Redis/KV hoặc một shared store.
