import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';
import 'package:trail_path/features/pro/application/premium_controller.dart';
import 'package:trail_path/features/settings/application/settings_controller.dart';

final activeNavigationProvider =
    NotifierProvider<ActiveNavigationController, ActiveNavigationState>(
      ActiveNavigationController.new,
    );

class ActiveNavigationState {
  const ActiveNavigationState({
    this.route,
    this.event,
    this.isActive = false,
    this.error,
  });

  final RoutePlan? route;
  final NavigationEvent? event;
  final bool isActive;
  final String? error;

  ActiveNavigationState copyWith({
    RoutePlan? route,
    NavigationEvent? event,
    bool? isActive,
    String? error,
    bool clearError = false,
  }) {
    return ActiveNavigationState(
      route: route ?? this.route,
      event: event ?? this.event,
      isActive: isActive ?? this.isActive,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ActiveNavigationController extends Notifier<ActiveNavigationState> {
  StreamSubscription<NavigationEvent>? _subscription;
  NavigationEngine? _engine;
  NavigationFeedback? _feedback;
  bool _rerouteInFlight = false;
  DateTime? _lastRerouteAt;

  @override
  ActiveNavigationState build() {
    ref.listen(batteryModeProvider, (previous, next) {
      next.whenData((mode) {
        if (state.isActive) {
          unawaited(_applyBatteryMode(mode));
        }
      });
    });
    ref.onDispose(() {
      final subscription = _subscription;
      _subscription = null;
      unawaited(subscription?.cancel() ?? Future<void>.value());

      final engine = _engine;
      if (engine != null) {
        unawaited(engine.stop());
      }

      final feedback = _feedback;
      if (feedback != null) {
        unawaited(feedback.stop());
      }
    });
    return const ActiveNavigationState();
  }

  Future<void> _applyBatteryMode(BatteryMode mode) async {
    try {
      final engine = _engine;
      if (engine != null) {
        await engine.setBatteryMode(mode);
      }
    } on Object {
      // Keep navigation alive if a platform stream cannot be reconfigured
      // while the activity is running.
    }
  }

  Future<void> start(
    RoutePlan route,
    String languageCode, {
    bool voiceGuidance = true,
  }) async {
    await _subscription?.cancel();
    if (!ref.mounted) {
      return;
    }
    state = ActiveNavigationState(route: route);

    try {
      final feedback = ref.read(navigationFeedbackProvider);
      _feedback = feedback;
      if (voiceGuidance) {
        try {
          await feedback.configure(languageCode);
        } on Object {
          // Voice feedback is optional. Navigation must continue if TTS is
          // unavailable or the device has no matching voice installed.
        }
      }
      final voice = _voiceMessages(languageCode);

      if (!ref.mounted) {
        return;
      }

      final engine = ref.read(navigationEngineProvider);
      _engine = engine;
      _subscription = engine.events.listen(
        (event) {
          if (!ref.mounted) {
            return;
          }
          state = state.copyWith(
            event: event,
            isActive: event.type != NavigationEventType.stopped,
            clearError: true,
          );

          switch (event.type) {
            case NavigationEventType.offRoute:
              unawaited(_safeAlert(feedback));
              if (voiceGuidance) {
                unawaited(_safeSpeak(feedback, voice.offRoute));
              }
              unawaited(_maybeAutoReroute(event));
            case NavigationEventType.backOnRoute:
              if (voiceGuidance) {
                unawaited(_safeSpeak(feedback, voice.backOnRoute));
              }
            case NavigationEventType.arrived:
              unawaited(_safeAlert(feedback));
              if (voiceGuidance) {
                unawaited(_safeSpeak(feedback, voice.arrived));
              }
            case NavigationEventType.started:
            case NavigationEventType.instruction:
            case NavigationEventType.stopped:
              break;
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!ref.mounted) {
            return;
          }
          state = state.copyWith(error: error.toString());
        },
      );

      final batteryMode = await ref.read(batteryModeProvider.future);
      if (!ref.mounted) {
        return;
      }
      await engine.start(route, mode: batteryMode);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isActive: true, clearError: true);
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isActive: false, error: error.toString());
      }
    }
  }

  Future<void> _maybeAutoReroute(NavigationEvent event) async {
    if (_rerouteInFlight || !state.isActive) {
      return;
    }
    final currentPoint = event.currentPoint;
    final activeRoute = state.route;
    if (currentPoint == null ||
        activeRoute == null ||
        activeRoute.geometry.length < 2) {
      return;
    }

    try {
      final preferences = await ref.read(settingsControllerProvider.future);
      final premium = ref.read(premiumControllerProvider);
      if (!preferences.autoReroute || !premium.isPro || !ref.mounted) {
        return;
      }

      final now = DateTime.now();
      final last = _lastRerouteAt;
      if (last != null && now.difference(last) < const Duration(seconds: 45)) {
        return;
      }

      _rerouteInFlight = true;
      final destination = activeRoute.geometry.last;
      final rerouted = await ref
          .read(routingEngineProvider)
          .calculate(
            RouteRequest(
              points: [currentPoint, destination],
              profile: activeRoute.profile,
              snapToNetwork: true,
            ),
          );

      if (!ref.mounted ||
          !state.isActive ||
          !rerouted.isSnapped ||
          rerouted.geometry.length < 2) {
        return;
      }

      final engine = _engine;
      if (engine == null) {
        return;
      }
      final batteryMode = await ref.read(batteryModeProvider.future);
      if (!ref.mounted || !state.isActive) {
        return;
      }

      _lastRerouteAt = now;
      state = state.copyWith(route: rerouted, clearError: true);
      await engine.start(rerouted, mode: batteryMode);
    } on Object {
      // Automatic rerouting is opportunistic. Keep the original route and
      // existing off-route guidance when routing/network is unavailable.
    } finally {
      _rerouteInFlight = false;
    }
  }

  Future<void> stop() async {
    final engine = _engine;
    final feedback = _feedback;
    final subscription = _subscription;
    _subscription = null;
    _rerouteInFlight = false;
    _lastRerouteAt = null;

    if (engine != null) {
      await engine.stop();
    }
    if (feedback != null) {
      try {
        await feedback.stop();
      } on Object {
        // TTS shutdown failures must not keep navigation state active.
      }
    }
    await subscription?.cancel();

    if (ref.mounted) {
      state = state.copyWith(isActive: false);
    }
  }
}

Future<void> _safeSpeak(NavigationFeedback feedback, String message) async {
  try {
    await feedback.speak(message);
  } on Object {
    // Voice guidance is best-effort.
  }
}

Future<void> _safeAlert(NavigationFeedback feedback) async {
  try {
    await feedback.alert();
  } on Object {
    // Haptics are best-effort.
  }
}

({String offRoute, String backOnRoute, String arrived}) _voiceMessages(
  String languageCode,
) {
  return switch (languageCode) {
    'it' => (
      offRoute: 'Fuori percorso',
      backOnRoute: 'Sei tornato sul percorso',
      arrived: 'Sei arrivato',
    ),
    'es' => (
      offRoute: 'Fuera de ruta',
      backOnRoute: 'Has vuelto a la ruta',
      arrived: 'Has llegado',
    ),
    'fr' => (
      offRoute: 'Hors parcours',
      backOnRoute: 'Vous êtes revenu sur le parcours',
      arrived: 'Vous êtes arrivé',
    ),
    'pt' => (
      offRoute: 'Fora do percurso',
      backOnRoute: 'Regressou ao percurso',
      arrived: 'Chegou ao destino',
    ),
    _ => (
      offRoute: 'Off route',
      backOnRoute: 'You are back on route',
      arrived: 'You have arrived',
    ),
  };
}
