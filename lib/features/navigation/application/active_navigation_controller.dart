import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';

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
      _subscription?.cancel();
    });
    return const ActiveNavigationState();
  }

  Future<void> _applyBatteryMode(BatteryMode mode) async {
    try {
      await ref.read(navigationEngineProvider).setBatteryMode(mode);
    } on Object {
      // Keep navigation alive if a platform stream cannot be reconfigured
      // while the activity is running.
    }
  }

  Future<void> start(RoutePlan route, String languageCode) async {
    await _subscription?.cancel();
    state = ActiveNavigationState(route: route);

    try {
      final feedback = ref.read(navigationFeedbackProvider);
      try {
        await feedback.configure(languageCode);
      } on Object {
        // Voice feedback is optional. Navigation must continue if TTS is
        // unavailable or the device has no matching voice installed.
      }
      final voice = _voiceMessages(languageCode);

      final engine = ref.read(navigationEngineProvider);
      _subscription = engine.events.listen(
        (event) {
          state = state.copyWith(
            event: event,
            isActive: event.type != NavigationEventType.stopped,
            clearError: true,
          );

          switch (event.type) {
            case NavigationEventType.offRoute:
              unawaited(_safeAlert(feedback));
              unawaited(_safeSpeak(feedback, voice.offRoute));
            case NavigationEventType.backOnRoute:
              unawaited(_safeSpeak(feedback, voice.backOnRoute));
            case NavigationEventType.arrived:
              unawaited(_safeAlert(feedback));
              unawaited(_safeSpeak(feedback, voice.arrived));
            case NavigationEventType.started:
            case NavigationEventType.instruction:
            case NavigationEventType.stopped:
              break;
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          state = state.copyWith(error: error.toString());
        },
      );

      final batteryMode = await ref.read(batteryModeProvider.future);
      await engine.start(route, mode: batteryMode);
      state = state.copyWith(isActive: true, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(isActive: false, error: error.toString());
    }
  }

  Future<void> stop() async {
    await ref.read(navigationEngineProvider).stop();
    try {
      await ref.read(navigationFeedbackProvider).stop();
    } on Object {
      // TTS shutdown failures must not keep navigation state active.
    }
    await _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isActive: false);
  }
}

Future<void> _safeSpeak(
  NavigationFeedback feedback,
  String message,
) async {
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
