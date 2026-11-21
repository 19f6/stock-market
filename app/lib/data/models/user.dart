import 'package:equatable/equatable.dart';

/// An authenticated account. Passwords are never stored in the clear — only
/// [passwordHash] (sha256 of salt + password) and [salt] are persisted.
class Account extends Equatable {
  final String username;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const Account({
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'salt': salt,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        username: j['username'] as String,
        passwordHash: j['passwordHash'] as String,
        salt: j['salt'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  @override
  List<Object?> get props => [username, passwordHash, salt, createdAt];
}
