part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStatusChanged extends AuthEvent {
  const AuthStatusChanged(this.status);
  final AuthStatus status;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthUserUpdated extends AuthEvent {
  const AuthUserUpdated(this.user);
  final UserModel user;
}
