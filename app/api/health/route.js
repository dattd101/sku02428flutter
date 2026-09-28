import { healthSnapshot } from '../../../lib/chat-server.mjs';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export function GET() {
  return Response.json(healthSnapshot());
}
