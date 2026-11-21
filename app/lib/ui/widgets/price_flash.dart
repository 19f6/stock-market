import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Shows a price and briefly flashes green/red whenever the value changes —
/// the classic "ticker" effect. Rebuilds many times per second safely.
class PriceFlash extends StatefulWidget {
  final double price;
  final TextStyle? style;
  const PriceFlash({super.key, required this.price, this.style});

  @override
  State<PriceFlash> createState() => _PriceFlashState();
}

class _PriceFlashState extends State<PriceFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double? _last;
  Color _flash = Colors.transparent;

  @override
  void didUpdateWidget(covariant PriceFlash old) {
    super.didUpdateWidget(old);
    if (_last != null && widget.price != _last) {
      _flash = widget.price > _last! ? AppTheme.up : AppTheme.down;
      _c.forward(from: 0);
    }
    _last = widget.price;
  }

  @override
  void initState() {
    super.initState();
    _last = widget.price;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: _flash.withValues(alpha: 0.30 * (1 - _c.value)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(money(widget.price), style: widget.style),
          ),
        );
      },
    );
  }
}
