import 'package:equatable/equatable.dart';

/// A live quote for one stock.
class Stock extends Equatable {
  final String symbol;
  final String name;
  final String sector;
  final String ipo;
  final double price;
  final double prevClose;
  final double change;
  final double changePct;

  const Stock({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.ipo,
    required this.price,
    required this.prevClose,
    required this.change,
    required this.changePct,
  });

  factory Stock.fromJson(Map<String, dynamic> j) => Stock(
        symbol: j['symbol'] as String,
        name: (j['name'] ?? j['symbol']) as String,
        sector: (j['sector'] ?? '') as String,
        ipo: (j['ipo'] ?? '') as String,
        price: (j['price'] as num).toDouble(),
        prevClose: (j['prevClose'] as num?)?.toDouble() ?? 0,
        change: (j['change'] as num?)?.toDouble() ?? 0,
        changePct: (j['changePct'] as num?)?.toDouble() ?? 0,
      );

  /// Apply a lightweight tick frame ({symbol, price, change, changePct}).
  Stock applyTick(Map<String, dynamic> j) => copyWith(
        price: (j['price'] as num).toDouble(),
        change: (j['change'] as num?)?.toDouble() ?? change,
        changePct: (j['changePct'] as num?)?.toDouble() ?? changePct,
      );

  Stock copyWith({
    double? price,
    double? prevClose,
    double? change,
    double? changePct,
  }) =>
      Stock(
        symbol: symbol,
        name: name,
        sector: sector,
        ipo: ipo,
        price: price ?? this.price,
        prevClose: prevClose ?? this.prevClose,
        change: change ?? this.change,
        changePct: changePct ?? this.changePct,
      );

  bool get isUp => change >= 0;

  @override
  List<Object?> get props =>
      [symbol, name, sector, ipo, price, prevClose, change, changePct];
}
