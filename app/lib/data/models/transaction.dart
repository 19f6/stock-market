import 'package:equatable/equatable.dart';

enum TradeSide { buy, sell }

/// A single executed trade, kept in the user's ledger.
class TxnRecord extends Equatable {
  final String symbol;
  final TradeSide side;
  final int quantity;
  final double price;
  final DateTime time;

  const TxnRecord({
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.time,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity,
        'price': price,
        'time': time.toIso8601String(),
      };

  factory TxnRecord.fromJson(Map<String, dynamic> j) => TxnRecord(
        symbol: j['symbol'] as String,
        side: TradeSide.values.byName(j['side'] as String),
        quantity: (j['quantity'] as num).toInt(),
        price: (j['price'] as num).toDouble(),
        time: DateTime.parse(j['time'] as String),
      );

  @override
  List<Object?> get props => [symbol, side, quantity, price, time];
}
