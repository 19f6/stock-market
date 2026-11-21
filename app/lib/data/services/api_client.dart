import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../models/candle.dart';
import '../models/stock.dart';

/// Thin REST client over the mock server.
class ApiClient {
  final http.Client _http;
  ApiClient([http.Client? client]) : _http = client ?? http.Client();

  Future<List<Stock>> fetchStocks() async {
    final res = await _get('/stocks');
    return (jsonDecode(res) as List)
        .map((e) => Stock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Stock> fetchStock(String symbol) async {
    final res = await _get('/stocks/${Uri.encodeComponent(symbol)}');
    return Stock.fromJson(jsonDecode(res) as Map<String, dynamic>);
  }

  /// range: 1m | 3m | 6m | 1y | 5y | max
  Future<History> fetchHistory(String symbol, String range) async {
    final res = await _get(
        '/stocks/${Uri.encodeComponent(symbol)}/history?range=$range');
    return History.fromJson(jsonDecode(res) as Map<String, dynamic>);
  }

  Future<String> _get(String path) async {
    final res = await _http
        .get(Uri.parse('${AppConfig.restBase}$path'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException('GET $path failed (${res.statusCode})');
    }
    return res.body;
  }

  void close() => _http.close();
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}
