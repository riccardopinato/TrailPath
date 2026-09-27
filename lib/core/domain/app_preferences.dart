import 'package:trail_path/core/domain/models.dart';

enum ThemePreference { system, light, dark }

enum DistanceUnitPreference { metric, imperial }

enum DefaultMapPreference { outdoor, street, satellite, hybrid }

class AppPreferences {
  const AppPreferences({
    this.theme = ThemePreference.system,
    this.units = DistanceUnitPreference.metric,
    this.defaultProfile = RouteProfile.hiking,
    this.defaultMap = DefaultMapPreference.outdoor,
    this.voiceGuidance = true,
    this.wifiOnlyDownloads = false,
  });

  final ThemePreference theme;
  final DistanceUnitPreference units;
  final RouteProfile defaultProfile;
  final DefaultMapPreference defaultMap;
  final bool voiceGuidance;
  final bool wifiOnlyDownloads;

  AppPreferences copyWith({
    ThemePreference? theme,
    DistanceUnitPreference? units,
    RouteProfile? defaultProfile,
    DefaultMapPreference? defaultMap,
    bool? voiceGuidance,
    bool? wifiOnlyDownloads,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      units: units ?? this.units,
      defaultProfile: defaultProfile ?? this.defaultProfile,
      defaultMap: defaultMap ?? this.defaultMap,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
    );
  }
}
