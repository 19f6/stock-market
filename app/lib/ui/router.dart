import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import 'pages/login_page.dart';
import 'pages/market_page.dart';
import 'pages/stock_detail_page.dart';
import 'pages/wallet_page.dart';

/// Builds the app router with an auth guard: unauthenticated users are always
/// redirected to /login; authenticated users are kept out of /login.
GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _BlocListenable(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      if (status == AuthStatus.unknown) return null;
      final loggedIn = status == AuthStatus.authenticated;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => _HomeShell(state: state, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const MarketPage()),
          GoRoute(path: '/wallet', builder: (_, _) => const WalletPage()),
        ],
      ),
      GoRoute(
        path: '/stock/:symbol',
        builder: (_, state) => StockDetailPage(
          symbol: Uri.decodeComponent(state.pathParameters['symbol']!),
        ),
      ),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;
  const _HomeShell({required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = state.matchedLocation;
    final index = loc.startsWith('/wallet') ? 1 : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            context.go(i == 0 ? '/' : '/wallet'),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: 'Market'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }
}

/// Adapts a Bloc stream to a Listenable for GoRouter.refreshListenable.
class _BlocListenable extends ChangeNotifier {
  _BlocListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
