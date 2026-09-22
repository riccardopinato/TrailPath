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
  String get mapLayers => _value('mapLayers');
  String get centerLocation => _value('centerLocation');
  String get locationServiceOff => _value('locationServiceOff');
  String get locationUnavailable => _value('locationUnavailable');
  String get locationPermissionNeeded => _value('locationPermissionNeeded');
  String get locationReady => _value('locationReady');
  String get locationWaiting => _value('locationWaiting');

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
      'foundationReady': 'Mappa e posizione attive',
      'mapLayers': 'Livelli mappa',
      'centerLocation': 'Centra sulla mia posizione',
      'locationServiceOff': 'Attiva i servizi di localizzazione',
      'locationUnavailable': 'Posizione temporaneamente non disponibile',
      'locationPermissionNeeded': 'Consenti l’accesso alla posizione',
      'locationReady': 'GPS attivo',
      'locationWaiting': 'In attesa della posizione',
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
      'foundationReady': 'Map and location active',
      'mapLayers': 'Map layers',
      'centerLocation': 'Center on my location',
      'locationServiceOff': 'Turn on location services',
      'locationUnavailable': 'Location temporarily unavailable',
      'locationPermissionNeeded': 'Allow location access',
      'locationReady': 'GPS active',
      'locationWaiting': 'Waiting for location',
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
      'foundationReady': 'Mapa y ubicación activos',
      'mapLayers': 'Capas del mapa',
      'centerLocation': 'Centrar en mi ubicación',
      'locationServiceOff': 'Activa los servicios de ubicación',
      'locationUnavailable': 'Ubicación temporalmente no disponible',
      'locationPermissionNeeded': 'Permite el acceso a la ubicación',
      'locationReady': 'GPS activo',
      'locationWaiting': 'Esperando ubicación',
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
      'foundationReady': 'Carte et position actives',
      'mapLayers': 'Couches de carte',
      'centerLocation': 'Centrer sur ma position',
      'locationServiceOff': 'Activez les services de localisation',
      'locationUnavailable': 'Position temporairement indisponible',
      'locationPermissionNeeded': 'Autorisez l’accès à la position',
      'locationReady': 'GPS actif',
      'locationWaiting': 'En attente de la position',
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
      'foundationReady': 'Mapa e localização ativos',
      'mapLayers': 'Camadas do mapa',
      'centerLocation': 'Centrar na minha localização',
      'locationServiceOff': 'Ative os serviços de localização',
      'locationUnavailable': 'Localização temporariamente indisponível',
      'locationPermissionNeeded': 'Permita o acesso à localização',
      'locationReady': 'GPS ativo',
      'locationWaiting': 'A aguardar localização',
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
