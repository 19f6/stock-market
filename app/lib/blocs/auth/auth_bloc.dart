import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignUpRequested extends AuthEvent {
  final String username;
  final String password;
  const AuthSignUpRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class AuthLogInRequested extends AuthEvent {
  final String username;
  final String password;
  const AuthLogInRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class AuthLogOutRequested extends AuthEvent {
  const AuthLogOutRequested();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? error;
  final bool submitting;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.error,
    this.submitting = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? error,
    bool? submitting,
  }) =>
      AuthState(
        status: status ?? this.status,
        username: username ?? this.username,
        error: error,
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props => [status, username, error, submitting];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>((event, emit) {
      final user = _repo.currentUser();
      emit(AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        username: user,
      ));
    });

    on<AuthSignUpRequested>((event, emit) async {
      emit(state.copyWith(submitting: true, error: null));
      try {
        final account = await _repo.signUp(event.username, event.password);
        emit(AuthState(
            status: AuthStatus.authenticated, username: account.username));
      } on AuthException catch (e) {
        emit(state.copyWith(submitting: false, error: e.message));
      }
    });

    on<AuthLogInRequested>((event, emit) async {
      emit(state.copyWith(submitting: true, error: null));
      try {
        final account = await _repo.logIn(event.username, event.password);
        emit(AuthState(
            status: AuthStatus.authenticated, username: account.username));
      } on AuthException catch (e) {
        emit(state.copyWith(submitting: false, error: e.message));
      }
    });

    on<AuthLogOutRequested>((event, emit) async {
      await _repo.logOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });
  }
}
