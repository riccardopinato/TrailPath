import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('it'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('it'));
  }

  String _value(String key) {
    final language = _values.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _values[language]?[key] ?? _values['en']?[key] ?? key;
  }

  String get planner => _value('planner');
  String get record => _value('record');
  String get routes => _value('routes');
  String get searchPlace => _value('searchPlace');
  String get createRoute => _value('createRoute');
  String get tapMapHint => _value('tapMapHint');
  String get distance => _value('distance');
  String get ascent => _value('ascent');
  String get duration => _value('duration');
  String get readyToRecord => _value('readyToRecord');
  String get startRecording => _value('startRecording');
  String get yourRoutes => _value('yourRoutes');
  String get noRoutes => _value('noRoutes');
  String get noRoutesHint => _value('noRoutesHint');
  String get foundationReady => _value('foundationReady');
  String get mapPositionReady => _value('mapPositionReady');
  String get mapLayers => _value('mapLayers');
  String get myLocation => _value('myLocation');
  String get gpsChecking => _value('gpsChecking');
  String get gpsWaiting => _value('gpsWaiting');
  String get gpsDisabled => _value('gpsDisabled');
  String get gpsPermissionRequired => _value('gpsPermissionRequired');
  String get gpsOpenSettings => _value('gpsOpenSettings');
  String get gpsUnavailable => _value('gpsUnavailable');

  String gpsAccuracy(double meters) {
    final rounded = meters.isFinite ? meters.round() : 0;
    return _value('gpsAccuracy').replaceFirst('{meters}', '$rounded');
  }

  static const Map<String, Map<String, String>> _values = {
    'it': {
      'planner': 'Pianifica',
      'record': 'Registra',
      'routes': 'Percorsi',
      'searchPlace': 'Cerca luogo o sentiero',
      'createRoute': 'Crea un percorso',
      'tapMapHint': 'Tocca la mappa per aggiungere il primo punto',
      'distance': 'Distanza',
      'ascent': 'Salita',
      'duration': 'Tempo',
      'readyToRecord': 'Pronto a registrare',
      'startRecording': 'Avvia registrazione',
      'yourRoutes': 'I tuoi percorsi',
      'noRoutes': 'Nessun percorso salvato',
      'noRoutesHint': 'I percorsi pianificati compariranno qui.',
      'foundationReady': 'Fondazione pronta',
      'mapPositionReady': 'Mappa reale e posizione GPS attive',
      'mapLayers': 'Livelli mappa',
      'myLocation': 'La mia posizione',
      'gpsChecking': 'Ricerca GPS…',
      'gpsWaiting': 'In attesa del segnale GPS',
      'gpsDisabled': 'GPS disattivato · tocca per attivarlo',
      'gpsPermissionRequired': 'Consenti la posizione',
      'gpsOpenSettings': 'Posizione bloccata · apri impostazioni',
      'gpsUnavailable': 'GPS non disponibile · riprova',
      'gpsAccuracy': 'GPS ±{meters} m',
    },
    'en': {
      'planner': 'Plan',
      'record': 'Record',
      'routes': 'Routes',
      'searchPlace': 'Search place or trail',
      'createRoute': 'Create a route',
      'tapMapHint': 'Tap the map to add the first point',
      'distance': 'Distance',
      'ascent': 'Ascent',
      'duration': 'Time',
      'readyToRecord': 'Ready to record',
      'startRecording': 'Start recording',
      'yourRoutes': 'Your routes',
      'noRoutes': 'No saved routes',
      'noRoutesHint': 'Routes you plan will appear here.',
      'foundationReady': 'Foundation ready',
      'mapPositionReady': 'Live map and GPS position enabled',
      'mapLayers': 'Map layers',
      'myLocation': 'My location',
      'gpsChecking': 'Finding GPS…',
      'gpsWaiting': 'Waiting for GPS signal',
      'gpsDisabled': 'GPS disabled · tap to enable',
      'gpsPermissionRequired': 'Allow location access',
      'gpsOpenSettings': 'Location blocked · open settings',
      'gpsUnavailable': 'GPS unavailable · retry',
      'gpsAccuracy': 'GPS ±{meters} m',
    },
    'es': {
      'planner': 'Planificar',
      'record': 'Registrar',
      'routes': 'Rutas',
      'searchPlace': 'Buscar lugar o sendero',
      'createRoute': 'Crear una ruta',
      'tapMapHint': 'Toca el mapa para añadir el primer punto',
      'distance': 'Distancia',
      'ascent': 'Ascenso',
      'duration': 'Tiempo',
      'readyToRecord': 'Listo para registrar',
      'startRecording': 'Iniciar registro',
      'yourRoutes': 'Tus rutas',
      'noRoutes': 'No hay rutas guardadas',
      'noRoutesHint': 'Las rutas planificadas aparecerán aquí.',
      'foundationReady': 'Base lista',
      'mapPositionReady': 'Mapa real y posición GPS activos',
      'mapLayers': 'Capas del mapa',
      'myLocation': 'Mi ubicación',
      'gpsChecking': 'Buscando GPS…',
      'gpsWaiting': 'Esperando señal GPS',
      'gpsDisabled': 'GPS desactivado · toca para activarlo',
      'gpsPermissionRequired': 'Permitir ubicación',
      'gpsOpenSettings': 'Ubicación bloqueada · abrir ajustes',
      'gpsUnavailable': 'GPS no disponible · reintentar',
      'gpsAccuracy': 'GPS ±{meters} m',
    },
    'fr': {
      'planner': 'Planifier',
      'record': 'Enregistrer',
      'routes': 'Parcours',
      'searchPlace': 'Rechercher un lieu ou sentier',
      'createRoute': 'Créer un parcours',
      'tapMapHint': 'Touchez la carte pour ajouter le premier point',
      'distance': 'Distance',
      'ascent': 'Montée',
      'duration': 'Temps',
      'readyToRecord': 'Prêt à enregistrer',
      'startRecording': 'Démarrer',
      'yourRoutes': 'Vos parcours',
      'noRoutes': 'Aucun parcours enregistré',
      'noRoutesHint': 'Vos parcours planifiés apparaîtront ici.',
      'foundationReady': 'Base prête',
      'mapPositionReady': 'Carte réelle et position GPS actives',
      'mapLayers': 'Couches de carte',
      'myLocation': 'Ma position',
      'gpsChecking': 'Recherche GPS…',
      'gpsWaiting': 'En attente du signal GPS',
      'gpsDisabled': 'GPS désactivé · toucher pour activer',
      'gpsPermissionRequired': 'Autoriser la localisation',
      'gpsOpenSettings': 'Localisation bloquée · ouvrir réglages',
      'gpsUnavailable': 'GPS indisponible · réessayer',
      'gpsAccuracy': 'GPS ±{meters} m',
    },
    'pt': {
      'planner': 'Planear',
      'record': 'Gravar',
      'routes': 'Percursos',
      'searchPlace': 'Pesquisar local ou trilho',
      'createRoute': 'Criar um percurso',
      'tapMapHint': 'Toque no mapa para adicionar o primeiro ponto',
      'distance': 'Distância',
      'ascent': 'Subida',
      'duration': 'Tempo',
      'readyToRecord': 'Pronto para gravar',
      'startRecording': 'Iniciar gravação',
      'yourRoutes': 'Os seus percursos',
      'noRoutes': 'Nenhum percurso guardado',
      'noRoutesHint': 'Os percursos planeados aparecerão aqui.',
      'foundationReady': 'Base pronta',
      'mapPositionReady': 'Mapa real e posição GPS ativos',
      'mapLayers': 'Camadas do mapa',
      'myLocation': 'A minha localização',
      'gpsChecking': 'A procurar GPS…',
      'gpsWaiting': 'A aguardar sinal GPS',
      'gpsDisabled': 'GPS desativado · toque para ativar',
      'gpsPermissionRequired': 'Permitir localização',
      'gpsOpenSettings': 'Localização bloqueada · abrir definições',
      'gpsUnavailable': 'GPS indisponível · tentar novamente',
      'gpsAccuracy': 'GPS ±{meters} m',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (candidate) => candidate.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
