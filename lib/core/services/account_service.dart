import 'package:trail_path/core/domain/account.dart';

abstract interface class AccountService {
  bool get isConfigured;

  Future<AccountProfile?> initialize();

  Future<AccountProfile?> signIn();

  Future<void> signOut();

  Future<AccountAuthTokens?> authTokens({bool promptIfNeeded = false});
}
