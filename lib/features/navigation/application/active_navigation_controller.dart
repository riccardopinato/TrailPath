import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/models.dart';
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
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const ActiveNavigationState();
  }

  Future<void> start(RoutePlan route, String languageCode) async {
    await _subscription?.cancel();
    state = ActiveNavigationState(route: route);

    try {
      final feedback = ref.read(navigationFeedbackProvider);
      await feedback.configure(languageCode);
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
              unawaited(feedback.alert());
              unawaited(feedback.speak(voice.offRoute));
            case NavigationEventType.backOnRoute:
              unawaited(feedback.speak(voice.backOnRoute));
            case NavigationEventType.arrived:
              unawaited(feedback.alert());
              unawaited(feedback.speak(voice.arrived));
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
    await ref.read(navigationFeedbackProvider).stop();
    await _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isActive: false);
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
