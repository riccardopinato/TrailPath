import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/account.dart';
import 'package:trail_path/core/services/account_service.dart';
import 'package:trail_path/infrastructure/auth/google_account_service.dart';

final accountServiceProvider = Provider<AccountService>(
  (ref) => GoogleAccountService(),
);

final accountControllerProvider =
    NotifierProvider<AccountController, AccountState>(
      AccountController.new,
    );

class AccountController extends Notifier<AccountState> {
  late AccountService _service;

  @override
  AccountState build() {
    _service = ref.watch(accountServiceProvider);
    unawaited(_initialize());
    return AccountState(
      isLoading: true,
      isConfigured: _service.isConfigured,
    );
  }

  Future<void> _initialize() async {
    try {
      final profile = await _service.initialize();
      if (ref.mounted) {
        state = AccountState(
          isLoading: false,
          isConfigured: _service.isConfigured,
          profile: profile,
        );
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = AccountState(
          isLoading: false,
          isConfigured: _service.isConfigured,
          error: error.toString(),
        );
      }
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.signIn();
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          profile: profile,
          clearError: true,
        );
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false, error: error.toString());
      }
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.signOut();
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          clearProfile: true,
          clearError: true,
        );
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false, error: error.toString());
      }
    }
  }

  Future<AccountAuthTokens?> authTokens({bool promptIfNeeded = false}) =>
      _service.authTokens(promptIfNeeded: promptIfNeeded);
}
