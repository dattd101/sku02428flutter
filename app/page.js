export default function Home() {
  return (
    <main style={{ fontFamily: 'system-ui', padding: 32, lineHeight: 1.6 }}>
      <h1>SKU02428 Flutter WebSocket Server</h1>
      <p>Realtime backend dành riêng cho ứng dụng Flutter.</p>
      <p>WebSocket endpoint: <code>/api/ws</code></p>
      <p>Health endpoint: <a href="/api/health">/api/health</a></p>
    </main>
  );
}
