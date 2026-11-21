import 'package:equatable/equatable.dart';

/// A position in one stock: how many shares and the average price paid.
class Holding extends Equatable {
  final String symbol;
  final int quantity;
  final double avgCost;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
  });

  double get costBasis => quantity * avgCost;
  double marketValue(double price) => quantity * price;
  double unrealizedPnl(double price) => marketValue(price) - costBasis;
  double unrealizedPnlPct(double price) =>
      costBasis == 0 ? 0 : unrealizedPnl(price) / costBasis * 100;

  Holding copyWith({int? quantity, double? avgCost}) => Holding(
        symbol: symbol,
        quantity: quantity ?? this.quantity,
        avgCost: avgCost ?? this.avgCost,
      );

  Map<String, dynamic> toJson() =>
      {'symbol': symbol, 'quantity': quantity, 'avgCost': avgCost};

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
        symbol: j['symbol'] as String,
        quantity: (j['quantity'] as num).toInt(),
        avgCost: (j['avgCost'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [symbol, quantity, avgCost];
}
