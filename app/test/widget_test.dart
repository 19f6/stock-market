import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_market/data/repositories/auth_repository.dart';
import 'package:stock_market/data/repositories/portfolio_repository.dart';
import 'package:stock_market/data/models/transaction.dart';
import 'package:stock_market/data/services/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore.create();
  }

  test('sign up creates an account and starts a session', () async {
    final auth = AuthRepository(await freshStore());
    final account = await auth.signUp('trader', 'secret1');
    expect(account.username, 'trader');
    expect(auth.currentUser(), 'trader');
  });

  test('duplicate usernames are rejected', () async {
    final auth = AuthRepository(await freshStore());
    await auth.signUp('sam', 'secret1');
    expect(() => auth.signUp('sam', 'another'), throwsA(isA<AuthException>()));
  });

  test('wrong password fails login', () async {
    final auth = AuthRepository(await freshStore());
    await auth.signUp('kim', 'secret1');
    await auth.logOut();
    expect(() => auth.logIn('kim', 'nope'), throwsA(isA<AuthException>()));
  });

  test('new portfolio starts with one million dollars', () async {
    final repo = PortfolioRepository(await freshStore());
    final p = repo.load('trader');
    expect(p.cash, 1000000.0);
    expect(p.holdings, isEmpty);
  });

  test('buy then sell updates cash and holdings', () async {
    final repo = PortfolioRepository(await freshStore());
    var p = await repo.buy('trader', 'AAPL', 10, 200);
    expect(p.cash, 1000000.0 - 2000);
    expect(p.holdings['AAPL']!.quantity, 10);

    p = await repo.sell('trader', 'AAPL', 4, 250);
    expect(p.holdings['AAPL']!.quantity, 6);
    expect(p.cash, 1000000.0 - 2000 + 1000);
    expect(p.transactions.last.side, TradeSide.sell);
  });

  test('cannot buy more than cash allows', () async {
    final repo = PortfolioRepository(await freshStore());
    expect(() => repo.buy('trader', 'AAPL', 100000, 999),
        throwsA(isA<TradeException>()));
  });

  test('cannot sell shares you do not own', () async {
    final repo = PortfolioRepository(await freshStore());
    expect(() => repo.sell('trader', 'AAPL', 1, 100),
        throwsA(isA<TradeException>()));
  });
}
