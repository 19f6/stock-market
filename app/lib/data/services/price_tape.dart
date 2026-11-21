import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/stock.dart';
import '../repositories/market_repository.dart';

/// Keeps a short rolling window of recent prices per symbol so the UI can draw
/// live sparklines. Fed straight from the market repository stream.
class PriceTape extends ChangeNotifier {
  final int capacity;
  final Map<String, Queue<double>> _tape = {};
  StreamSubscription<Map<String, Stock>>? _sub;

  PriceTape(MarketRepository repo, {this.capacity = 60}) {
    _sub = repo.watch().listen(_onQuotes);
  }

  void _onQuotes(Map<String, Stock> quotes) {
    for (final entry in quotes.entries) {
      final q = _tape.putIfAbsent(entry.key, () => Queue<double>());
      q.addLast(entry.value.price);
      while (q.length > capacity) {
        q.removeFirst();
      }
    }
    notifyListeners();
  }

  List<double> of(String symbol) =>
      _tape[symbol]?.toList(growable: false) ?? const [];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
