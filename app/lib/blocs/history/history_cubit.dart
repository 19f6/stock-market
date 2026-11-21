import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/candle.dart';
import '../../data/repositories/market_repository.dart';

/// Label -> server range param. Covers day / week / month / year / since-IPO.
const kRanges = <String, String>{
  '1D': '1d',
  '1W': '1w',
  '1M': '1m',
  '6M': '6m',
  '1Y': '1y',
  'MAX': 'max',
};

/// Ranges served as intraday (5-minute) bars — the chart labels these with
/// time-of-day instead of a date.
const kIntradayRanges = {'1D', '1W'};

enum HistoryStatus { initial, loading, ready, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final String symbol;
  final String rangeLabel;
  final History? history;
  final String? error;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.symbol = '',
    this.rangeLabel = '1Y',
    this.history,
    this.error,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    String? symbol,
    String? rangeLabel,
    History? history,
    String? error,
  }) =>
      HistoryState(
        status: status ?? this.status,
        symbol: symbol ?? this.symbol,
        rangeLabel: rangeLabel ?? this.rangeLabel,
        history: history ?? this.history,
        error: error,
      );

  @override
  List<Object?> get props => [status, symbol, rangeLabel, history, error];
}

class HistoryCubit extends Cubit<HistoryState> {
  final MarketRepository _repo;
  HistoryCubit(this._repo) : super(const HistoryState());

  Future<void> load(String symbol, {String rangeLabel = '1Y'}) async {
    emit(state.copyWith(
      status: HistoryStatus.loading,
      symbol: symbol,
      rangeLabel: rangeLabel,
      error: null,
    ));
    try {
      final h = await _repo.history(symbol, kRanges[rangeLabel] ?? '1y');
      emit(state.copyWith(status: HistoryStatus.ready, history: h));
    } catch (e) {
      emit(state.copyWith(status: HistoryStatus.error, error: e.toString()));
    }
  }

  Future<void> changeRange(String rangeLabel) =>
      load(state.symbol, rangeLabel: rangeLabel);
}
