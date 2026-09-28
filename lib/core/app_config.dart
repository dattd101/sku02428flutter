class AppConfig {
  // Recommended: flutter run --dart-define=WS_URL=wss://YOUR-SERVER
  static const wsUrl = String.fromEnvironment('WS_URL', defaultValue: 'ws://10.0.2.2:8080');
  static const maxMessageLength = 2000;
  static const maxFileSize = 3670016; // 3.5 MiB
  static const fileChunkBytes = 90 * 1024; // base64 remains under server 128 KiB limit
}
