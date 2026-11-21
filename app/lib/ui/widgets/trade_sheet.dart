import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/market/market_bloc.dart';
import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../core/theme.dart';
import '../../data/models/transaction.dart';

/// Bottom sheet for buying or selling a stock at the live price.
class TradeSheet extends StatefulWidget {
  final String symbol;
  final TradeSide side;
  const TradeSheet({super.key, required this.symbol, required this.side});

  static Future<void> show(
      BuildContext context, String symbol, TradeSide side) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TradeSheet(symbol: symbol, side: side),
      ),
    );
  }

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  final _qtyCtrl = TextEditingController(text: '1');
  int get _qty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.side == TradeSide.buy;
    final live = context.select<MarketBloc, double?>(
        (b) => b.state[widget.symbol]?.price);
    final portfolio = context.watch<PortfolioBloc>().state.portfolio;
    final cash = portfolio?.cash ?? 0;
    final owned = portfolio?.holdings[widget.symbol]?.quantity ?? 0;
    final price = live ?? 0;
    final total = price * _qty;
    final canAfford = isBuy ? total <= cash : _qty <= owned;
    final valid = _qty > 0 && price > 0 && canAfford;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${isBuy ? 'Buy' : 'Sell'} ${widget.symbol}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Live price  ${money(price)}',
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Quantity'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _row('Order total', money(total)),
          _row(isBuy ? 'Cash available' : 'Shares owned',
              isBuy ? money(cash) : '$owned'),
          if (isBuy) _row('Cash after', money(cash - total)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isBuy ? AppTheme.up : AppTheme.down,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: valid
                ? () {
                    context.read<PortfolioBloc>().add(TradeRequested(
                          side: widget.side,
                          symbol: widget.symbol,
                          quantity: _qty,
                          price: price,
                        ));
                    Navigator.of(context).pop();
                  }
                : null,
            child: Text(isBuy
                ? 'Buy $_qty for ${money(total)}'
                : 'Sell $_qty for ${money(total)}'),
          ),
          if (!canAfford && _qty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isBuy ? 'Not enough cash.' : 'You only own $owned shares.',
                style: const TextStyle(color: AppTheme.down),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
