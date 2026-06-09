part of 'auth_bloc.dart';

class AuthState {
  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(UserModel user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final UserModel? user;
}
