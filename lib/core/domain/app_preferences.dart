import 'package:trail_path/core/domain/models.dart';

enum ThemePreference { system, light, dark }

enum DefaultMapPreference { outdoor, street, highContrast, satellite, hybrid }

class AppPreferences {
  const AppPreferences({
    this.theme = ThemePreference.system,
    this.defaultProfile = RouteProfile.hiking,
    this.defaultMap = DefaultMapPreference.outdoor,
    this.voiceGuidance = true,
    this.wifiOnlyDownloads = false,
    this.autoReroute = false,
  });

  final ThemePreference theme;
  final RouteProfile defaultProfile;
  final DefaultMapPreference defaultMap;
  final bool voiceGuidance;
  final bool wifiOnlyDownloads;
  final bool autoReroute;

  AppPreferences copyWith({
    ThemePreference? theme,
    RouteProfile? defaultProfile,
    DefaultMapPreference? defaultMap,
    bool? voiceGuidance,
    bool? wifiOnlyDownloads,
    bool? autoReroute,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      defaultProfile: defaultProfile ?? this.defaultProfile,
      defaultMap: defaultMap ?? this.defaultMap,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      autoReroute: autoReroute ?? this.autoReroute,
    );
  }
}
