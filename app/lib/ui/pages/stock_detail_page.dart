import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/history/history_cubit.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../core/theme.dart';
import '../../data/models/candle.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/market_repository.dart';
import '../widgets/price_chart.dart';
import '../widgets/price_flash.dart';
import '../widgets/trade_sheet.dart';

/// Historical data + charts + trading for a single stock.
class StockDetailPage extends StatelessWidget {
  final String symbol;
  const StockDetailPage({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HistoryCubit(context.read<MarketRepository>())..load(symbol),
      child: _StockDetailView(symbol: symbol),
    );
  }
}

class _StockDetailView extends StatelessWidget {
  final String symbol;
  const _StockDetailView({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final stock = context.select<MarketBloc, dynamic>((b) => b.state[symbol]);
    return Scaffold(
      appBar: AppBar(title: Text(symbol)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- live quote header ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stock?.name ?? symbol,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(stock?.sector ?? '',
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              if (stock != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriceFlash(
                      price: stock.price,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${signedPct(stock.changePct)}  ${money(stock.change)} today',
                      style: TextStyle(color: AppTheme.trend(stock.change)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // --- historical chart + range selector ---
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 240,
                    child: switch (state.status) {
                      HistoryStatus.ready => PriceChart(
                          history: state.history!,
                          intraday:
                              kIntradayRanges.contains(state.rangeLabel),
                        ),
                      HistoryStatus.error => Center(
                          child: Text('Could not load history.\n${state.error}',
                              textAlign: TextAlign.center)),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final label in kRanges.keys)
                        ChoiceChip(
                          label: Text(label),
                          selected: state.rangeLabel == label,
                          onSelected: (_) => context
                              .read<HistoryCubit>()
                              .changeRange(label),
                        ),
                    ],
                  ),
                  if (state.status == HistoryStatus.ready) ...[
                    const SizedBox(height: 16),
                    _HistoryStats(history: state.history!),
                    const SizedBox(height: 16),
                    _HistoryTable(
                      history: state.history!,
                      intraday: kIntradayRanges.contains(state.rangeLabel),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: stock == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.up,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => TradeSheet.show(
                            context, symbol, TradeSide.buy),
                        icon: const Icon(Icons.add),
                        label: const Text('Buy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.down,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => TradeSheet.show(
                            context, symbol, TradeSide.sell),
                        icon: const Icon(Icons.remove),
                        label: const Text('Sell'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HistoryStats extends StatelessWidget {
  final History history;
  const _HistoryStats({required this.history});

  @override
  Widget build(BuildContext context) {
    final c = history.candles;
    var lo = c.first.low, hi = c.first.high;
    for (final x in c) {
      if (x.low < lo) lo = x.low;
      if (x.high > hi) hi = x.high;
    }
    final owned = context.select<PortfolioBloc, int>(
        (b) => b.state.portfolio?.holdings[history.symbol]?.quantity ?? 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            _stat('Range', history.range.toUpperCase()),
            _stat('Period change', signedPct(history.changePct),
                color: AppTheme.trend(history.changePct)),
            _stat('Period high', money(hi)),
            _stat('Period low', money(lo)),
            _stat('Bars', '${c.length}'),
            _stat('You own', '$owned shares'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _HistoryTable extends StatelessWidget {
  final History history;
  final bool intraday;
  const _HistoryTable({required this.history, this.intraday = false});

  @override
  Widget build(BuildContext context) {
    final rows = history.candles.reversed.take(30).toList();
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Historical data — ${history.range.toUpperCase()} (most recent 30 bars)',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(intraday ? 'Time' : 'Date')),
                const DataColumn(label: Text('Open'), numeric: true),
                const DataColumn(label: Text('High'), numeric: true),
                const DataColumn(label: Text('Low'), numeric: true),
                const DataColumn(label: Text('Close'), numeric: true),
                const DataColumn(label: Text('Volume'), numeric: true),
              ],
              rows: [
                for (final c in rows)
                  DataRow(cells: [
                    DataCell(Text(
                        intraday ? fmtDateTime(c.time) : fmtDate(c.time))),
                    DataCell(Text(c.open.toStringAsFixed(2))),
                    DataCell(Text(c.high.toStringAsFixed(2))),
                    DataCell(Text(c.low.toStringAsFixed(2))),
                    DataCell(Text(c.close.toStringAsFixed(2))),
                    DataCell(Text('${c.volume}')),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
