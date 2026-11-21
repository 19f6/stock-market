import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models/holding.dart';
import '../../data/models/transaction.dart';

/// Holdings ordered by current market value, largest first.
List<Holding> sortedHoldings(Iterable<Holding> holdings, MarketState market) {
  double value(Holding h) =>
      (market[h.symbol]?.price ?? h.avgCost) * h.quantity;
  return holdings.toList()..sort((a, b) => value(b).compareTo(value(a)));
}

/// The user's wallet: cash, holdings with quantities, live portfolio value.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogOutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, pf) {
          final portfolio = pf.portfolio;
          if (portfolio == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return BlocBuilder<MarketBloc, MarketState>(
            builder: (context, market) {
              double holdingsValue = 0;
              double costBasis = 0;
              for (final h in portfolio.holdings.values) {
                final price = market[h.symbol]?.price ?? h.avgCost;
                holdingsValue += h.quantity * price;
                costBasis += h.costBasis;
              }
              final total = portfolio.cash + holdingsValue;
              final pnl = holdingsValue - costBasis;
              final totalReturn = total - AppConfig.startingBalance;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(
                    total: total,
                    cash: portfolio.cash,
                    holdingsValue: holdingsValue,
                    dayPnl: pnl,
                    totalReturn: totalReturn,
                  ),
                  const SizedBox(height: 20),
                  Text('Holdings (${portfolio.holdings.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (portfolio.holdings.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: Text(
                                'No stocks yet. Open the Market tab to buy.')),
                      ),
                    )
                  else
                    ...sortedHoldings(portfolio.holdings.values, market)
                        .map((h) {
                      final price = market[h.symbol]?.price ?? h.avgCost;
                      final value = h.quantity * price;
                      final gain = h.unrealizedPnl(price);
                      return Card(
                        child: ListTile(
                          onTap: () => context.push(
                              '/stock/${Uri.encodeComponent(h.symbol)}'),
                          title: Text(h.symbol,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${h.quantity} @ ${money(h.avgCost)} avg  ·  now ${money(price)}'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(money(value),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '${gain >= 0 ? '+' : ''}${money(gain)} (${signedPct(h.unrealizedPnlPct(price))})',
                                style: TextStyle(
                                    color: AppTheme.trend(gain), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Text('Recent transactions',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (portfolio.transactions.isEmpty)
                    const Text('None yet.',
                        style: TextStyle(color: Colors.white54))
                  else
                    ...portfolio.transactions.reversed.take(20).map((t) {
                      final buy = t.side == TradeSide.buy;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          buy ? Icons.south_west : Icons.north_east,
                          color: buy ? AppTheme.up : AppTheme.down,
                        ),
                        title: Text(
                            '${buy ? 'Buy' : 'Sell'} ${t.quantity} ${t.symbol}'),
                        subtitle: Text(fmtDate(t.time)),
                        trailing: Text(money(t.total)),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total, cash, holdingsValue, dayPnl, totalReturn;
  const _SummaryCard({
    required this.total,
    required this.cash,
    required this.holdingsValue,
    required this.dayPnl,
    required this.totalReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Portfolio value',
                style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 4),
            Text(money(total),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              '${totalReturn >= 0 ? '+' : ''}${money(totalReturn)} all-time  ·  ${signedPct(totalReturn / AppConfig.startingBalance * 100)}',
              style: TextStyle(color: AppTheme.trend(totalReturn)),
            ),
            const Divider(height: 28),
            _row('Cash', money(cash)),
            _row('Holdings value', money(holdingsValue)),
            _row('Unrealized P/L', '${dayPnl >= 0 ? '+' : ''}${money(dayPnl)}',
                color: AppTheme.trend(dayPnl)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            Text(value,
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
}
