import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalSession { final String id; final String username; const LocalSession(this.id,this.username); }
class SessionStore {
  static const _id='tempchat_session_id', _name='tempchat_username';
  final _uuid=const Uuid();
  Future<LocalSession> load() async {
    final p=await SharedPreferences.getInstance();
    var id=p.getString(_id); var name=p.getString(_name);
    id ??= _uuid.v4(); name ??= 'user_${DateTime.now().millisecondsSinceEpoch}';
    await save(id,name); return LocalSession(id,name);
  }
  Future<void> save(String id,String name) async { final p=await SharedPreferences.getInstance(); await p.setString(_id,id); await p.setString(_name,name); }
  Future<void> clear() async { final p=await SharedPreferences.getInstance(); await p.remove(_id); await p.remove(_name); }
}
