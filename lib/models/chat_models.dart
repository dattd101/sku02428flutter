class ChatUser {
  final String id;
  final String username;
  const ChatUser({required this.id, required this.username});
  factory ChatUser.fromJson(Map<String, dynamic> j) => ChatUser(id: '${j['id'] ?? ''}', username: '${j['username'] ?? ''}');
  Map<String,dynamic> toJson() => {'id':id,'username':username};
}

class ChatMessage {
  final String id;
  final String fromId;
  final String text;
  final int timestamp;
  final bool mine;
  final String? fileName;
  final int? fileSize;
  final List<int>? fileBytes;
  const ChatMessage({required this.id, required this.fromId, required this.text, required this.timestamp, required this.mine, this.fileName, this.fileSize, this.fileBytes});
}

class ChatRoom {
  final String id;
  final ChatUser peer;
  final int createdAt;
  final int expiresAt;
  int attachmentCount;
  int maxFileSends;
  bool peerOnline;
  int unread;
  final List<ChatMessage> messages;
  ChatRoom({required this.id,required this.peer,required this.createdAt,required this.expiresAt,this.attachmentCount=0,this.maxFileSends=30,this.peerOnline=true,this.unread=0,List<ChatMessage>? messages}):messages=messages??[];
  factory ChatRoom.fromJson(Map<String,dynamic> j) => ChatRoom(id:'${j['id']}',peer:ChatUser.fromJson(Map<String,dynamic>.from(j['peer']??{})),createdAt:(j['createdAt'] as num?)?.toInt()??DateTime.now().millisecondsSinceEpoch,expiresAt:(j['expiresAt'] as num?)?.toInt()??0,attachmentCount:(j['attachmentCount'] as num?)?.toInt()??0,maxFileSends:(j['maxFileSends'] as num?)?.toInt()??30);
}

class ChatRequest {
  final String requestId;
  final ChatUser from;
  final int expiresAt;
  const ChatRequest({required this.requestId,required this.from,required this.expiresAt});
}
