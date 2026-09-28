import { EventEmitter } from 'node:events';
import { registerConnection } from '../lib/chat-server.mjs';

class FakeSocket extends EventEmitter {
  constructor() {
    super();
    this.readyState = 1;
    this.sent = [];
  }

  send(raw) {
    this.sent.push(JSON.parse(raw));
  }

  ping() {}

  take(type) {
    const index = this.sent.findIndex((item) => item.type === type);
    if (index < 0) throw new Error(`Missing event: ${type}`);
    return this.sent.splice(index, 1)[0];
  }

  clear() {
    this.sent.length = 0;
  }
}

const emit = (socket, value) => {
  socket.emit('message', Buffer.from(JSON.stringify(value)));
};

const sender = new FakeSocket();
const receiver = new FakeSocket();
registerConnection(sender);
registerConnection(receiver);

emit(sender, { type: 'hello', username: 'alice-file-test' });
emit(receiver, { type: 'hello', username: 'bob-file-test' });
sender.take('session_ready');
const receiverUser = receiver.take('session_ready').user;
sender.clear();
receiver.clear();

emit(sender, { type: 'chat_request', targetUserId: receiverUser.id });
const request = receiver.take('chat_request');
emit(receiver, { type: 'chat_accept', requestId: request.requestId });
const chat = sender.take('chat_created').chat;
receiver.take('chat_created');
sender.clear();
receiver.clear();

emit(sender, {
  type: 'file_start',
  chatId: chat.id,
  transferId: 'failed-transfer',
  file: { name: 'broken.txt', type: 'text/plain', size: 10 },
  batchPosition: 2,
  batchTotal: 4,
});
const started = sender.take('file_start');
if (started.attachmentCount !== 1) throw new Error('File slot was not counted.');
if (started.batchPosition !== 2 || started.batchTotal !== 4) {
  throw new Error('File batch progress was not relayed.');
}
const receiverStarted = receiver.take('file_start');
if (receiverStarted.batchPosition !== 2 || receiverStarted.batchTotal !== 4) {
  throw new Error('Receiver did not get file batch progress.');
}

emit(sender, { type: 'file_end', chatId: chat.id, transferId: 'failed-transfer' });
const senderAbort = sender.take('file_abort');
const receiverAbort = receiver.take('file_abort');
if (senderAbort.attachmentCount !== 0 || receiverAbort.attachmentCount !== 0) {
  throw new Error('Failed file slot was not restored.');
}
if (sender.sent.some((item) => item.type === 'error')) {
  throw new Error('A duplicate file error was emitted.');
}

emit(sender, {
  type: 'message',
  chatId: chat.id,
  clientMessageId: 'after-failure',
  text: 'chat vẫn hoạt động',
});
const afterFailure = receiver.take('message');
if (afterFailure.text !== 'chat vẫn hoạt động' || sender.readyState !== 1 || receiver.readyState !== 1) {
  throw new Error('Chat did not survive the failed file transfer.');
}

emit(sender, {
  type: 'file_start',
  chatId: chat.id,
  transferId: 'too-large',
  file: {
    name: 'large.bin',
    type: 'application/octet-stream',
    size: 3.5 * 1024 * 1024 + 1,
  },
});
const tooLarge = sender.take('error');
if (tooLarge.code !== 'FILE_TOO_LARGE' || !tooLarge.message.includes('3.5 MB')) {
  throw new Error('The 3.5 MB boundary was not enforced.');
}

emit(sender, { type: 'chat_close', chatId: chat.id });
console.log('File failure regression test passed.');
