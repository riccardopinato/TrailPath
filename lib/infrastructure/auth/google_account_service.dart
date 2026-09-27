import 'package:google_sign_in/google_sign_in.dart';
import 'package:trail_path/core/config/account_config.dart';
import 'package:trail_path/core/domain/account.dart';
import 'package:trail_path/core/services/account_service.dart';

class GoogleAccountService implements AccountService {
  GoogleAccountService({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  GoogleSignInAccount? _account;
  bool _initialized = false;

  @override
  bool get isConfigured => AccountConfig.hasGoogleConfiguration;

  @override
  Future<AccountProfile?> initialize() async {
    if (!isConfigured) {
      return null;
    }
    if (!_initialized) {
      await _signIn.initialize(
        serverClientId: AccountConfig.googleServerClientId,
      );
      _initialized = true;
    }

    final attempt = _signIn.attemptLightweightAuthentication();
    if (attempt == null) {
      return null;
    }
    try {
      _account = await attempt;
      return _profile(_account);
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<AccountProfile?> signIn() async {
    if (!isConfigured) {
      throw StateError('Google Sign-In is not configured.');
    }
    if (!_initialized) {
      await _signIn.initialize(
        serverClientId: AccountConfig.googleServerClientId,
      );
      _initialized = true;
    }
    if (!_signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Interactive Google Sign-In is not supported on this platform.',
      );
    }
    _account = await _signIn.authenticate();
    return _profile(_account);
  }

  @override
  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
  }

  @override
  Future<String?> idToken() async {
    final account = _account;
    if (account == null) {
      return null;
    }
    return account.authentication.idToken;
  }

  AccountProfile? _profile(GoogleSignInAccount? account) {
    if (account == null) {
      return null;
    }
    return AccountProfile(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}
