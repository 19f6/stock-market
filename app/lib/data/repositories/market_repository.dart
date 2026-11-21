import 'dart:async';

import '../models/candle.dart';
import '../models/stock.dart';
import '../services/api_client.dart';
import '../services/market_socket.dart';

/// Single source of truth for market data. Seeds from REST, then keeps an
/// in-memory table of quotes updated by the WebSocket tick stream and
/// re-broadcasts the whole table on every tick.
class MarketRepository {
  final ApiClient _api;
  final MarketSocket _socket;

  MarketRepository({ApiClient? api, MarketSocket? socket})
      : _api = api ?? ApiClient(),
        _socket = socket ?? MarketSocket();

  final Map<String, Stock> _quotes = {};
  StreamController<Map<String, Stock>>? _controller;
  StreamSubscription<MarketFrame>? _socketSub;

  Map<String, Stock> get snapshot => Map.unmodifiable(_quotes);

  /// Broadcast stream of the full quote table, emitted on every socket frame.
  Stream<Map<String, Stock>> watch() {
    _controller ??= StreamController<Map<String, Stock>>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  Future<void> _start() async {
    // Seed synchronously-ish from REST so the UI has data before the first tick.
    try {
      final list = await _api.fetchStocks();
      for (final s in list) {
        _quotes[s.symbol] = s;
      }
      _emit();
    } catch (_) {/* socket snapshot will fill in */}

    _socketSub = _socket.connect().listen((frame) {
      for (final q in frame.quotes) {
        final sym = q['symbol'] as String;
        final existing = _quotes[sym];
        if (frame.type == 'snapshot' || existing == null) {
          _quotes[sym] = Stock.fromJson(q);
        } else {
          _quotes[sym] = existing.applyTick(q);
        }
      }
      _emit();
    });
  }

  void _stop() {
    _socketSub?.cancel();
    _socketSub = null;
  }

  void _emit() {
    if (_controller?.hasListener ?? false) {
      _controller!.add(Map.unmodifiable(_quotes));
    }
  }

  Future<History> history(String symbol, String range) =>
      _api.fetchHistory(symbol, range);

  Future<Stock> quote(String symbol) => _api.fetchStock(symbol);

  Future<void> dispose() async {
    await _socketSub?.cancel();
    await _socket.dispose();
    await _controller?.close();
    _api.close();
  }
}
