/// Central configuration for the mock data server.
///
/// The mock server (see `../server`) exposes REST on http://HOST:8080 and a
/// WebSocket on ws://HOST:8080. Override at build time with:
///   flutter run --dart-define=API_HOST=192.168.1.20
class AppConfig {
  static const String _host =
      String.fromEnvironment('API_HOST', defaultValue: 'localhost');
  static const int _port =
      int.fromEnvironment('API_PORT', defaultValue: 8080);

  static String get restBase => 'http://$_host:$_port';
  static String get wsUrl => 'ws://$_host:$_port';

  /// How often the real-time UI is allowed to repaint from the socket stream.
  /// The socket itself delivers ~6 ticks/sec; we forward all of them (>= 5/sec).
  static const Duration uiTickInterval = Duration(milliseconds: 150);

  static const double startingBalance = 1000000.0;
}
