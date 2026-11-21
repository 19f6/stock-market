import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config.dart';

/// A decoded frame from the market WebSocket.
class MarketFrame {
  final String type; // 'snapshot' | 'tick'
  final int ts;
  final List<Map<String, dynamic>> quotes;
  MarketFrame(this.type, this.ts, this.quotes);

  factory MarketFrame.fromJson(Map<String, dynamic> j) => MarketFrame(
        j['type'] as String,
        (j['ts'] as num?)?.toInt() ?? 0,
        (j['quotes'] as List).cast<Map<String, dynamic>>(),
      );
}

/// Maintains a WebSocket connection to the mock server and exposes a broadcast
/// stream of [MarketFrame]s, auto-reconnecting on drop.
class MarketSocket {
  WebSocketChannel? _channel;
  StreamController<MarketFrame>? _out;
  StreamSubscription? _sub;
  Timer? _reconnect;
  bool _closed = false;

  Stream<MarketFrame> connect() {
    _out ??= StreamController<MarketFrame>.broadcast(
      onListen: _open,
      onCancel: () {
        // keep the socket alive for other listeners; nothing to do here.
      },
    );
    if (_channel == null) _open();
    return _out!.stream;
  }

  void _open() {
    if (_closed || _channel != null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final map = jsonDecode(data as String) as Map<String, dynamic>;
            _out?.add(MarketFrame.fromJson(map));
          } catch (_) {/* ignore malformed frame */}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _channel = null;
    if (_closed || _out == null || !_out!.hasListener) return;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 2), _open);
  }

  Future<void> dispose() async {
    _closed = true;
    _reconnect?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _out?.close();
  }
}
