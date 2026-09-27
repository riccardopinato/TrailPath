class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

class AccountState {
  const AccountState({
    this.isLoading = false,
    this.isConfigured = false,
    this.profile,
    this.error,
  });

  const AccountState.initial() : this(isLoading: true);

  final bool isLoading;
  final bool isConfigured;
  final AccountProfile? profile;
  final String? error;

  bool get isSignedIn => profile != null;

  AccountState copyWith({
    bool? isLoading,
    bool? isConfigured,
    AccountProfile? profile,
    bool clearProfile = false,
    String? error,
    bool clearError = false,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      isConfigured: isConfigured ?? this.isConfigured,
      profile: clearProfile ? null : profile ?? this.profile,
      error: clearError ? null : error ?? this.error,
    );
  }
}


class AccountAuthTokens {
  const AccountAuthTokens({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;
  final String accessToken;
}
