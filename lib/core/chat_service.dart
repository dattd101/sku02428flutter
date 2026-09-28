import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_models.dart';
import 'app_config.dart';
import 'session_store.dart';

class ChatService extends ChangeNotifier {
  final SessionStore store;
  ChatService(this.store);
  WebSocketChannel? _channel; StreamSubscription? _sub; Timer? _reconnect; bool _manual=false;
  String status='connecting', error='', sessionId='', username=''; int onlineCount=0; int tabIndex=1;
  final List<ChatUser> searchResults=[]; final List<ChatRequest> requests=[]; final Map<String,ChatRoom> chats={}; String? activeChatId; String notice='';
  final Map<String,_IncomingFile> _incoming={};
  ChatRoom? get activeChat => activeChatId==null?null:chats[activeChatId];

  Future<void> start() async { final s=await store.load(); sessionId=s.id; username=s.username; notifyListeners(); _connect(); }
  void _connect(){
    _reconnect?.cancel(); if(_manual)return; status=status=='online'?'reconnecting':'connecting'; error=''; notifyListeners();
    try {
      final c=WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl)); _channel=c;
      c.ready.then((_){ if(_channel!=c)return; _send({'type':'hello','sessionId':sessionId,'username':username}); }).catchError((e){_schedule('$e');});
      _sub=c.stream.listen(_onData,onError:(e)=>_schedule('$e'),onDone:()=>_schedule('Mất kết nối WebSocket.'));
    } catch(e){_schedule('$e');}
  }
  void _schedule(String e){ if(_manual)return; status='reconnecting'; error=e; notifyListeners(); _reconnect?.cancel(); _reconnect=Timer(const Duration(seconds:2),_connect); }
  bool _send(Map<String,dynamic> p){ try{_channel?.sink.add(jsonEncode(p)); return true;}catch(_){return false;} }
  void _onData(dynamic raw){
    Map<String,dynamic> d; try{d=Map<String,dynamic>.from(jsonDecode(raw as String));}catch(_){return;}
    switch(d['type']){
      case 'session_ready':
        status='online'; error=''; onlineCount=(d['onlineUsers'] as num?)?.toInt()??0; final u=ChatUser.fromJson(Map<String,dynamic>.from(d['user'])); sessionId=u.id; username=u.username; store.save(sessionId,username);
        final resumed=d['resumed']==true; if(!resumed)chats.clear();
        for(final x in (d['chats'] as List? ?? const [])){ final room=ChatRoom.fromJson(Map<String,dynamic>.from(x)); final old=chats[room.id]; if(old!=null)room.messages.addAll(old.messages); chats[room.id]=room; }
        break;
      case 'online_count': onlineCount=(d['onlineUsers'] as num?)?.toInt()??0; break;
      case 'search_results': searchResults..clear()..addAll((d['users'] as List? ?? const []).map((x)=>ChatUser.fromJson(Map<String,dynamic>.from(x)))); break;
      case 'chat_request': requests.add(ChatRequest(requestId:'${d['requestId']}',from:ChatUser.fromJson(Map<String,dynamic>.from(d['from'])),expiresAt:(d['expiresAt'] as num?)?.toInt()??0)); break;
      case 'chat_request_cancelled': requests.removeWhere((r)=>r.requestId==d['requestId']); break;
      case 'chat_request_sent': notice='Đã gửi yêu cầu tới @${d['to']?['username']}'; break;
      case 'chat_rejected': notice='@${d['by']?['username']} đã từ chối yêu cầu.'; break;
      case 'chat_created':
        requests.removeWhere((r)=>r.requestId==d['requestId']); final room=ChatRoom.fromJson(Map<String,dynamic>.from(d['chat'])); final old=chats[room.id]; if(old!=null)room.messages.addAll(old.messages); chats[room.id]=room; activeChatId=room.id; tabIndex=0; notice='Đã kết nối với @${room.peer.username}'; break;
      case 'message':
        final room=chats['${d['chatId']}']; if(room!=null){room.messages.add(ChatMessage(id:'${d['messageId']}',fromId:'${d['from']?['id']}',text:'${d['text']}',timestamp:(d['timestamp'] as num?)?.toInt()??DateTime.now().millisecondsSinceEpoch,mine:false)); if(activeChatId!=room.id)room.unread++;} break;
      case 'peer_status': final r=chats['${d['chatId']}']; if(r!=null)r.peerOnline=d['online']==true; break;
      case 'peer_disconnected': case 'chat_expired': case 'chat_closed': final id='${d['chatId']}'; chats.remove(id); if(activeChatId==id)activeChatId=null; notice=d['type']=='chat_expired'?'Cuộc chat đã hết hạn.':'Cuộc chat đã kết thúc.'; break;
      case 'file_start':
        final id='${d['transferId']}'; final from='${d['from']?['id']}'; final room=chats['${d['chatId']}']; if(room!=null)room.attachmentCount=(d['attachmentCount'] as num?)?.toInt()??room.attachmentCount; if(from!=sessionId){_incoming[id]=_IncomingFile(chatId:'${d['chatId']}',name:'${d['file']?['name']}',size:(d['file']?['size'] as num?)?.toInt()??0,fromId:from,timestamp:(d['timestamp'] as num?)?.toInt()??DateTime.now().millisecondsSinceEpoch);} break;
      case 'file_chunk': final f=_incoming['${d['transferId']}']; if(f!=null){try{f.bytes.addAll(base64Decode('${d['data']}'));}catch(_){}} break;
      case 'file_end': final f=_incoming.remove('${d['transferId']}'); final room=f==null?null:chats[f.chatId]; if(f!=null&&room!=null)room.messages.add(ChatMessage(id:'file_${d['transferId']}',fromId:f.fromId,text:'',timestamp:f.timestamp,mine:false,fileName:f.name,fileSize:f.size,fileBytes:Uint8List.fromList(f.bytes))); break;
      case 'file_abort': _incoming.remove('${d['transferId']}'); notice='${d['message']??'Gửi file thất bại.'}'; break;
      case 'error': notice='${d['message']??'Có lỗi xảy ra.'}'; break;
      case 'session_ended': status='offline'; break;
    } notifyListeners();
  }
  void setTab(int i){tabIndex=i; notifyListeners();}
  void search(String q){final v=q.trim().replaceFirst(RegExp(r'^@'),''); if(v.length<2){searchResults.clear();notifyListeners();return;} _send({'type':'search_users','query':v});}
  void requestChat(ChatUser u)=>_send({'type':'chat_request','targetUserId':u.id});
  void answer(ChatRequest r,bool accept){_send({'type':accept?'chat_accept':'chat_reject','requestId':r.requestId}); requests.removeWhere((x)=>x.requestId==r.requestId); notifyListeners();}
  void openChat(String id){if(chats.containsKey(id)){activeChatId=id;chats[id]!.unread=0;tabIndex=0;notifyListeners();}}
  void showChatList(){activeChatId=null;notifyListeners();}
  void sendMessage(String text){final room=activeChat; final t=text.trim(); if(room==null||t.isEmpty||t.length>AppConfig.maxMessageLength)return; final id=const Uuid().v4(); if(_send({'type':'message','chatId':room.id,'clientMessageId':id,'text':t})){room.messages.add(ChatMessage(id:id,fromId:sessionId,text:t,timestamp:DateTime.now().millisecondsSinceEpoch,mine:true));notifyListeners();}}
  Future<void> pickAndSendFile() async {final room=activeChat;if(room==null)return; final picked=await FilePicker.platform.pickFiles(withData:true); if(picked==null)return; final f=picked.files.single; final bytes=f.bytes; if(bytes==null){notice='Không đọc được file.';notifyListeners();return;} if(bytes.length>AppConfig.maxFileSize){notice='File vượt quá 3.5 MB.';notifyListeners();return;} final tid=const Uuid().v4(); _send({'type':'file_start','transferId':tid,'chatId':room.id,'file':{'name':f.name,'type':'application/octet-stream','size':bytes.length},'batchPosition':1,'batchTotal':1}); await Future.delayed(const Duration(milliseconds:120)); for(int i=0;i<bytes.length;i+=AppConfig.fileChunkBytes){final end=(i+AppConfig.fileChunkBytes<bytes.length)?i+AppConfig.fileChunkBytes:bytes.length; _send({'type':'file_chunk','transferId':tid,'chatId':room.id,'data':base64Encode(bytes.sublist(i,end))}); await Future.delayed(const Duration(milliseconds:10));} _send({'type':'file_end','transferId':tid,'chatId':room.id}); room.messages.add(ChatMessage(id:'file_$tid',fromId:sessionId,text:'',timestamp:DateTime.now().millisecondsSinceEpoch,mine:true,fileName:f.name,fileSize:bytes.length,fileBytes:bytes)); notifyListeners(); }
  void closeChat(String id){_send({'type':'chat_close','chatId':id});chats.remove(id);if(activeChatId==id)activeChatId=null;notifyListeners();}
  Future<void> endSession() async {_manual=true;_send({'type':'end_session'});await _sub?.cancel();await _channel?.sink.close();await store.clear();chats.clear();requests.clear();searchResults.clear();final s=await store.load();sessionId=s.id;username=s.username;_manual=false;_connect();notifyListeners();}
  @override void dispose(){_manual=true;_reconnect?.cancel();_sub?.cancel();_channel?.sink.close();super.dispose();}
}
class _IncomingFile {final String chatId,name,fromId;final int size,timestamp;final List<int> bytes=[];_IncomingFile({required this.chatId,required this.name,required this.size,required this.fromId,required this.timestamp});}
