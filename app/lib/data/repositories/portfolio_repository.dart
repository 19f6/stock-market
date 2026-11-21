import '../../core/config.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../services/local_store.dart';

/// The persisted state of one user's account funds + positions + ledger.
class Portfolio {
  final double cash;
  final Map<String, Holding> holdings;
  final List<TxnRecord> transactions;

  const Portfolio({
    required this.cash,
    required this.holdings,
    required this.transactions,
  });

  factory Portfolio.initial() => const Portfolio(
        cash: AppConfig.startingBalance,
        holdings: {},
        transactions: [],
      );

  double get investedCost =>
      holdings.values.fold(0.0, (sum, h) => sum + h.costBasis);

  Map<String, dynamic> toJson() => {
        'cash': cash,
        'holdings': holdings.values.map((h) => h.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Portfolio.fromJson(Map<String, dynamic> j) => Portfolio(
        cash: (j['cash'] as num).toDouble(),
        holdings: {
          for (final h in (j['holdings'] as List))
            (h['symbol'] as String):
                Holding.fromJson((h as Map).cast<String, dynamic>())
        },
        transactions: (j['transactions'] as List)
            .map((t) => TxnRecord.fromJson((t as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class TradeException implements Exception {
  final String message;
  TradeException(this.message);
  @override
  String toString() => message;
}

class PortfolioRepository {
  final LocalStore _store;
  PortfolioRepository(this._store);

  Portfolio load(String user) {
    final raw = _store.readPortfolio(user);
    if (raw == null) {
      final fresh = Portfolio.initial();
      _store.writePortfolio(user, fresh.toJson());
      return fresh;
    }
    return Portfolio.fromJson(raw);
  }

  Future<Portfolio> _save(String user, Portfolio p) async {
    await _store.writePortfolio(user, p.toJson());
    return p;
  }

  Future<Portfolio> buy(
      String user, String symbol, int qty, double price) async {
    if (qty <= 0) throw TradeException('Quantity must be positive.');
    final p = load(user);
    final cost = qty * price;
    if (cost > p.cash) {
      throw TradeException('Not enough cash for this order.');
    }
    final existing = p.holdings[symbol];
    final newHolding = existing == null
        ? Holding(symbol: symbol, quantity: qty, avgCost: price)
        : existing.copyWith(
            quantity: existing.quantity + qty,
            avgCost: (existing.costBasis + cost) / (existing.quantity + qty),
          );
    final holdings = Map<String, Holding>.from(p.holdings)
      ..[symbol] = newHolding;
    return _save(
      user,
      Portfolio(
        cash: p.cash - cost,
        holdings: holdings,
        transactions: [
          ...p.transactions,
          TxnRecord(
              symbol: symbol,
              side: TradeSide.buy,
              quantity: qty,
              price: price,
              time: DateTime.now()),
        ],
      ),
    );
  }

  Future<Portfolio> sell(
      String user, String symbol, int qty, double price) async {
    if (qty <= 0) throw TradeException('Quantity must be positive.');
    final p = load(user);
    final existing = p.holdings[symbol];
    if (existing == null || existing.quantity < qty) {
      throw TradeException('You do not own that many shares.');
    }
    final holdings = Map<String, Holding>.from(p.holdings);
    if (existing.quantity == qty) {
      holdings.remove(symbol);
    } else {
      holdings[symbol] = existing.copyWith(quantity: existing.quantity - qty);
    }
    return _save(
      user,
      Portfolio(
        cash: p.cash + qty * price,
        holdings: holdings,
        transactions: [
          ...p.transactions,
          TxnRecord(
              symbol: symbol,
              side: TradeSide.sell,
              quantity: qty,
              price: price,
              time: DateTime.now()),
        ],
      ),
    );
  }
}
