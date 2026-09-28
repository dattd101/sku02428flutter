import 'package:flutter/material.dart';
import 'core/chat_service.dart';
import 'core/session_store.dart';
import 'screens/chat_screen.dart';
import 'screens/social_screen.dart';
import 'screens/settings_screen.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const TempChatApp());}
class TempChatApp extends StatefulWidget{const TempChatApp({super.key});@override State<TempChatApp> createState()=>_TempChatAppState();}
class _TempChatAppState extends State<TempChatApp>{late final ChatService service;@override void initState(){super.initState();service=ChatService(SessionStore())..start();}@override void dispose(){service.dispose();super.dispose();}
@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'SKU02428 Chat',theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xff246bfd),scaffoldBackgroundColor:const Color(0xfff8faff),fontFamily:'sans-serif'),home:AnimatedBuilder(animation:service,builder:(context,_){final pages=[ChatScreen(service:service),SocialScreen(service:service),SettingsScreen(service:service)];return Scaffold(body:SafeArea(child:pages[service.tabIndex]),bottomNavigationBar:NavigationBar(selectedIndex:service.tabIndex,onDestinationSelected:service.setTab,destinations:const [NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'Chat'),NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Social'),NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'Settings')]),); }));}
}
