import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/stock.dart';
import '../../data/repositories/market_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
abstract class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => [];
}

class MarketStarted extends MarketEvent {
  const MarketStarted();
}

class _MarketTicked extends MarketEvent {
  final Map<String, Stock> quotes;
  const _MarketTicked(this.quotes);
  @override
  List<Object?> get props => [quotes];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum MarketStatus { initial, live, error }

class MarketState extends Equatable {
  final MarketStatus status;
  final Map<String, Stock> quotes;
  final int tickCount;

  /// Measured update rate (frames/sec) from the live stream.
  final double updatesPerSec;

  const MarketState({
    this.status = MarketStatus.initial,
    this.quotes = const {},
    this.tickCount = 0,
    this.updatesPerSec = 0,
  });

  List<Stock> get sorted {
    final list = quotes.values.toList()
      ..sort((a, b) => a.symbol.compareTo(b.symbol));
    return list;
  }

  Stock? operator [](String symbol) => quotes[symbol];

  MarketState copyWith({
    MarketStatus? status,
    Map<String, Stock>? quotes,
    int? tickCount,
    double? updatesPerSec,
  }) =>
      MarketState(
        status: status ?? this.status,
        quotes: quotes ?? this.quotes,
        tickCount: tickCount ?? this.tickCount,
        updatesPerSec: updatesPerSec ?? this.updatesPerSec,
      );

  @override
  List<Object?> get props => [status, quotes, tickCount, updatesPerSec];
}

// ---------------------------------------------------------------------------
// Bloc — streams the full quote table from the repository (>= 5 updates/sec).
// ---------------------------------------------------------------------------
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final MarketRepository _repo;
  StreamSubscription<Map<String, Stock>>? _sub;
  final List<DateTime> _recentTicks = [];

  MarketBloc(this._repo) : super(const MarketState()) {
    on<MarketStarted>(_onStarted);
    on<_MarketTicked>(_onTicked);
  }

  void _onStarted(MarketStarted event, Emitter<MarketState> emit) {
    _sub?.cancel();
    _sub = _repo.watch().listen(
      (quotes) => add(_MarketTicked(quotes)),
      onError: (_) => add(const _MarketTicked({})),
    );
  }

  void _onTicked(_MarketTicked event, Emitter<MarketState> emit) {
    if (event.quotes.isEmpty && state.quotes.isEmpty) {
      emit(state.copyWith(status: MarketStatus.error));
      return;
    }
    final now = DateTime.now();
    _recentTicks.add(now);
    final windowStart = now.subtract(const Duration(seconds: 2));
    _recentTicks.removeWhere((t) => t.isBefore(windowStart));
    final rate = _recentTicks.length / 2.0;

    emit(state.copyWith(
      status: MarketStatus.live,
      quotes: event.quotes.isEmpty ? state.quotes : event.quotes,
      tickCount: state.tickCount + 1,
      updatesPerSec: rate,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
