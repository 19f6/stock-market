import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences with JSON helpers. This is the app's "database":
/// accounts, the active session, and each user's portfolio live here.
class LocalStore {
  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  static Future<LocalStore> create() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _kAccounts = 'accounts';        // { username: accountJson }
  static const _kSession = 'session_user';     // active username or null
  String _portfolioKey(String user) => 'portfolio::$user';

  // --- accounts -----------------------------------------------------------
  Map<String, dynamic> readAccounts() {
    final raw = _prefs.getString(_kAccounts);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> writeAccounts(Map<String, dynamic> accounts) =>
      _prefs.setString(_kAccounts, jsonEncode(accounts));

  // --- session ----------------------------------------------------------
  String? readSession() => _prefs.getString(_kSession);
  Future<void> writeSession(String? user) => user == null
      ? _prefs.remove(_kSession)
      : _prefs.setString(_kSession, user);

  // --- portfolio -------------------------------------------------------
  Map<String, dynamic>? readPortfolio(String user) {
    final raw = _prefs.getString(_portfolioKey(user));
    if (raw == null) return null;
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> writePortfolio(String user, Map<String, dynamic> data) =>
      _prefs.setString(_portfolioKey(user), jsonEncode(data));
}
