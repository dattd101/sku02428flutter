import http from 'node:http';
import { WebSocketServer } from 'ws';
import {
  healthSnapshot,
  MAX_WS_PAYLOAD,
  originAllowed,
  registerConnection,
} from './lib/chat-server.mjs';

const PORT = Number(process.env.PORT || 8080);

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify(healthSnapshot()));
    return;
  }
  res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
  res.end('Temp Chat WebSocket server');
});

const wss = new WebSocketServer({
  server,
  maxPayload: MAX_WS_PAYLOAD,
  verifyClient: ({ origin, req }) => {
    const allowed = originAllowed(origin);
    if (!allowed) {
      console.warn(`[ws] rejected origin=${origin || 'unknown'} ip=${req?.socket?.remoteAddress || 'unknown'}`);
    }
    return allowed;
  },
});

wss.on('connection', (ws, req) => {
  registerConnection(ws, {
    origin: req?.headers?.origin || 'unknown',
    ip: req?.socket?.remoteAddress || 'unknown',
  });
});

server.on('error', (error) => {
  console.error(`[server] ${error.code || error.name}: ${error.message}`);
});

server.listen(PORT, () => {
  console.log(`Temp Chat WS server listening on port ${PORT}`);
  console.log(`WebSocket endpoint: ws://127.0.0.1:${PORT}`);
});
