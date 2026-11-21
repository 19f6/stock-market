import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/portfolio_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();
  @override
  List<Object?> get props => [];
}

class PortfolioLoaded extends PortfolioEvent {
  final String username;
  const PortfolioLoaded(this.username);
  @override
  List<Object?> get props => [username];
}

class PortfolioCleared extends PortfolioEvent {
  const PortfolioCleared();
}

class TradeRequested extends PortfolioEvent {
  final TradeSide side;
  final String symbol;
  final int quantity;
  final double price;
  const TradeRequested({
    required this.side,
    required this.symbol,
    required this.quantity,
    required this.price,
  });
  @override
  List<Object?> get props => [side, symbol, quantity, price];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum PortfolioStatus { empty, ready }

class PortfolioState extends Equatable {
  final PortfolioStatus status;
  final String? username;
  final Portfolio? portfolio;
  final String? error;
  final String? lastMessage;

  const PortfolioState({
    this.status = PortfolioStatus.empty,
    this.username,
    this.portfolio,
    this.error,
    this.lastMessage,
  });

  PortfolioState copyWith({
    PortfolioStatus? status,
    String? username,
    Portfolio? portfolio,
    String? error,
    String? lastMessage,
  }) =>
      PortfolioState(
        status: status ?? this.status,
        username: username ?? this.username,
        portfolio: portfolio ?? this.portfolio,
        error: error,
        lastMessage: lastMessage,
      );

  @override
  List<Object?> get props =>
      [status, username, portfolio?.cash, portfolio?.holdings, portfolio?.transactions.length, error, lastMessage];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------
class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final PortfolioRepository _repo;

  PortfolioBloc(this._repo) : super(const PortfolioState()) {
    on<PortfolioLoaded>((event, emit) {
      final p = _repo.load(event.username);
      emit(PortfolioState(
        status: PortfolioStatus.ready,
        username: event.username,
        portfolio: p,
      ));
    });

    on<PortfolioCleared>((event, emit) => emit(const PortfolioState()));

    on<TradeRequested>((event, emit) async {
      final user = state.username;
      if (user == null) return;
      try {
        final updated = event.side == TradeSide.buy
            ? await _repo.buy(user, event.symbol, event.quantity, event.price)
            : await _repo.sell(user, event.symbol, event.quantity, event.price);
        final verb = event.side == TradeSide.buy ? 'Bought' : 'Sold';
        emit(state.copyWith(
          status: PortfolioStatus.ready,
          portfolio: updated,
          error: null,
          lastMessage:
              '$verb ${event.quantity} ${event.symbol} @ \$${event.price.toStringAsFixed(2)}',
        ));
      } on TradeException catch (e) {
        emit(state.copyWith(error: e.message, lastMessage: null));
      }
    });
  }
}
