import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/user.dart';
import '../services/local_store.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Local authentication: account creation, credential checking, and session
/// persistence. Passwords are salted + sha256 hashed before storage.
class AuthRepository {
  final LocalStore _store;
  AuthRepository(this._store);

  final _rng = Random.secure();

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Returns the current session's username, if any.
  String? currentUser() => _store.readSession();

  Future<Account> signUp(String username, String password) async {
    username = username.trim();
    if (username.length < 3) {
      throw AuthException('Username must be at least 3 characters.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    final accounts = _store.readAccounts();
    if (accounts.containsKey(username.toLowerCase())) {
      throw AuthException('That username is already taken.');
    }
    final salt = _newSalt();
    final account = Account(
      username: username,
      passwordHash: _hash(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    accounts[username.toLowerCase()] = account.toJson();
    await _store.writeAccounts(accounts);
    await _store.writeSession(username);
    return account;
  }

  Future<Account> logIn(String username, String password) async {
    username = username.trim();
    final accounts = _store.readAccounts();
    final raw = accounts[username.toLowerCase()];
    if (raw == null) throw AuthException('No account for "$username".');
    final account = Account.fromJson((raw as Map).cast<String, dynamic>());
    if (_hash(password, account.salt) != account.passwordHash) {
      throw AuthException('Incorrect password.');
    }
    await _store.writeSession(account.username);
    return account;
  }

  Future<void> logOut() => _store.writeSession(null);

  Account? loadAccount(String username) {
    final raw = _store.readAccounts()[username.toLowerCase()];
    if (raw == null) return null;
    return Account.fromJson((raw as Map).cast<String, dynamic>());
  }
}
