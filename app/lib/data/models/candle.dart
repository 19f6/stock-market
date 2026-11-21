import 'package:equatable/equatable.dart';

/// One OHLC bar of historical data.
class Candle extends Equatable {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromJson(Map<String, dynamic> j) => Candle(
        time: DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt(),
            isUtc: true),
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
        volume: (j['volume'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [time, open, high, low, close, volume];
}

/// A full historical series for one symbol.
class History {
  final String symbol;
  final String range;
  final List<Candle> candles;

  const History({required this.symbol, required this.range, required this.candles});

  factory History.fromJson(Map<String, dynamic> j) => History(
        symbol: j['symbol'] as String,
        range: (j['range'] ?? '') as String,
        candles: (j['candles'] as List)
            .map((e) => Candle.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isEmpty => candles.isEmpty;
  double get first => candles.first.close;
  double get last => candles.last.close;
  double get changePct => first == 0 ? 0 : (last - first) / first * 100;
}
