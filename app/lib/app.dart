import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/market/market_bloc.dart';
import 'blocs/portfolio/portfolio_bloc.dart';
import 'core/theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/portfolio_repository.dart';
import 'data/services/local_store.dart';
import 'data/services/price_tape.dart';
import 'ui/router.dart';

class StockMarketApp extends StatelessWidget {
  final LocalStore store;
  const StockMarketApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final marketRepo = MarketRepository();
    final authRepo = AuthRepository(store);
    final portfolioRepo = PortfolioRepository(store);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: marketRepo),
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: portfolioRepo),
      ],
      child: ChangeNotifierProvider(
        create: (_) => PriceTape(marketRepo),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(authRepo)..add(const AuthStarted()),
            ),
            BlocProvider(
              create: (_) => MarketBloc(marketRepo)..add(const MarketStarted()),
            ),
            BlocProvider(
              create: (_) => PortfolioBloc(portfolioRepo),
            ),
          ],
          child: const _Root(),
        ),
      ),
    );
  }
}

/// Wires auth state to the portfolio bloc (load on login, clear on logout)
/// and builds the router once.
class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final _router = buildRouter(context.read<AuthBloc>());

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) =>
          a.status != b.status || a.username != b.username,
      listener: (context, state) {
        final pf = context.read<PortfolioBloc>();
        if (state.status == AuthStatus.authenticated &&
            state.username != null) {
          pf.add(PortfolioLoaded(state.username!));
        } else if (state.status == AuthStatus.unauthenticated) {
          pf.add(const PortfolioCleared());
        }
      },
      child: MaterialApp.router(
        title: 'Mock Market',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
