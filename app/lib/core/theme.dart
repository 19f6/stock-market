import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// App theme + shared formatters.
class AppTheme {
  static const up = Color(0xFF16A34A);
  static const down = Color(0xFFDC2626);
  static const _seed = Color(0xFF2563EB);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B0F14),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF141A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  static Color trend(num v) => v >= 0 ? up : down;
}

final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _moneyCompact = NumberFormat.compactCurrency(symbol: '\$');
final _pct = NumberFormat('+0.00;-0.00');
final _date = DateFormat('MMM d, yyyy');
final _dateShort = DateFormat('MMM d');
final _dateTime = DateFormat('MMM d, HH:mm');
final _timeShort = DateFormat('HH:mm');

String money(num v) => _money.format(v);
String moneyCompact(num v) => _moneyCompact.format(v);
String signedPct(num v) => '${_pct.format(v)}%';
String fmtDate(DateTime d) => _date.format(d.toLocal());
String fmtDateShort(DateTime d) => _dateShort.format(d.toLocal());
String fmtDateTime(DateTime d) => _dateTime.format(d.toLocal());
String fmtTimeShort(DateTime d) => _timeShort.format(d.toLocal());
