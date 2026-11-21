import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/market/market_bloc.dart';
import '../../data/models/stock.dart';
import '../../data/services/price_tape.dart';
import '../../core/theme.dart';
import '../widgets/price_flash.dart';
import '../widgets/sparkline.dart';

/// Real-time watchlist of the 20 monitored stocks.
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          BlocBuilder<MarketBloc, MarketState>(
            buildWhen: (a, b) =>
                a.status != b.status ||
                a.updatesPerSec.round() != b.updatesPerSec.round(),
            builder: (context, state) {
              final live = state.status == MarketStatus.live;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(children: [
                  Icon(Icons.circle,
                      size: 10, color: live ? AppTheme.up : Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    live
                        ? 'LIVE · ${state.updatesPerSec.toStringAsFixed(0)}/s'
                        : 'connecting…',
                    style: const TextStyle(fontSize: 12),
                  ),
                ]),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MarketBloc, MarketState>(
        builder: (context, state) {
          if (state.quotes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final stocks = state.sorted;
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<MarketBloc>().add(const MarketStarted()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: stocks.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _StockRow(stock: stocks[i]),
            ),
          );
        },
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final Stock stock;
  const _StockRow({required this.stock});

  @override
  Widget build(BuildContext context) {
    final tape = context.watch<PriceTape>().of(stock.symbol);
    final color = AppTheme.trend(stock.change);
    return ListTile(
      onTap: () => context.push('/stock/${Uri.encodeComponent(stock.symbol)}'),
      title: Text(stock.symbol,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(stock.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 28,
            child: Sparkline(points: tape, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              PriceFlash(
                price: stock.price,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                '${signedPct(stock.changePct)}  ${money(stock.change)}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
