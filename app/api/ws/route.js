import { experimental_upgradeWebSocket } from '@vercel/functions';
import { MAX_WS_PAYLOAD, originAllowed, registerConnection } from '../../../lib/chat-server.mjs';

export const runtime = 'nodejs';
export const maxDuration = 300;

export function GET(request) {
  const origin = request.headers.get('origin') || 'unknown';
  if (!originAllowed(origin)) {
    return new Response('Origin not allowed', { status: 403 });
  }

  return experimental_upgradeWebSocket((ws) => {
    registerConnection(ws, {
      origin,
      ip: request.headers.get('x-forwarded-for') || 'unknown',
    });
  }, { maxPayload: MAX_WS_PAYLOAD });
}
