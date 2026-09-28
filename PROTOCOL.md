# Protocol compatibility

Source of truth inspected: `sku02428-main/components/ChatApp.js` and `sku02428wss-main/lib/chat-server.mjs`.

## Session
`hello {sessionId, username}` -> `session_ready {resumed,user,onlineUsers,chats}`.

## Discovery / connection
`search_users {query}` -> `search_results {users}`.
`chat_request {targetUserId}` -> recipient `chat_request`; recipient answers `chat_accept` or `chat_reject`; success sends `chat_created` to both peers.

## Messaging
`message {chatId,clientMessageId,text}`. Server relays message to peer. Flutter immediately adds its own outgoing message locally, matching the web implementation behavior.

## Files
Chunked base64 transfer: `file_start`, `file_chunk`, `file_end`; server can emit `file_abort`. Chunk byte size is intentionally below the server's 128 KiB base64-frame validation threshold.

## Lifecycle
Server supports reconnect grace, `peer_status`, `chat_close`, `chat_expired`, `peer_disconnected`, and `end_session`.
