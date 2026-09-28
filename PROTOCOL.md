# SKU02428 Flutter WSS protocol

## State flow

`DISCONNECTED -> CONNECTING -> SESSION_READY -> SEARCHING -> REQUESTING/INCOMING -> CONNECTED -> CHAT -> CLOSED`

Session là tạm thời. Server không lưu message history.

## hello
Client gửi ngay khi socket mở. `sessionId` có thể dùng để resume trong grace period.

## session_ready
Server trả `user: {id, username}`, `resumed`, `graceMs`, `onlineUsers`, `chats`.

## search_users
Search chính xác username sau khi bỏ `@`, lowercase. Chỉ trả user khác đang online.

## chat_request / chat_accept / chat_reject
Request có TTL 30 giây. Accept tạo chat cho cả hai phía; nếu chat đã tồn tại server trả chat hiện tại.

## message
Server relay realtime tới peer. Server không persist message.

## files
`file_start -> file_chunk* -> file_end`. Client phải giữ `transferId`. Chunk là base64 và mỗi frame bị giới hạn.

## reconnect
Socket disconnect: user được giữ trong `DISCONNECT_GRACE_MS`. Client reconnect và gửi `hello` với `sessionId` cũ để resume.

## end_session
Xóa session, các chat liên quan và đóng socket.
