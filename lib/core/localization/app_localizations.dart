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
  String get tapMapContinue => _value('tapMapContinue');
  String get pointsShort => _value('pointsShort');
  String get waypoints => _value('waypoints');
  String get undo => _value('undo');
  String get redo => _value('redo');
  String get clear => _value('clear');
  String get saveRoute => _value('saveRoute');
  String get save => _value('save');
  String get cancel => _value('cancel');
  String get route => _value('route');
  String get routeName => _value('routeName');
  String get routeSaved => _value('routeSaved');
  String get profileHiking => _value('profileHiking');
  String get profileTrailRun => _value('profileTrailRun');
  String get profileWalking => _value('profileWalking');
  String get profileMtb => _value('profileMtb');
  String get profileCycling => _value('profileCycling');
  String get profileDogWalk => _value('profileDogWalk');
  String get delete => _value('delete');
  String get deleteRoute => _value('deleteRoute');
  String get routingReady => _value('routingReady');
  String get routingCalculating => _value('routingCalculating');
  String get routeSnapped => _value('routeSnapped');
  String get routeLocalFallback => _value('routeLocalFallback');

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
      'tapMapContinue': 'Tocca la mappa per aggiungere altri punti',
      'pointsShort': 'pt',
      'waypoints': 'Punti',
      'undo': 'Annulla',
      'redo': 'Ripristina',
      'clear': 'Pulisci',
      'saveRoute': 'Salva percorso',
      'save': 'Salva',
      'cancel': 'Annulla',
      'route': 'Percorso',
      'routeName': 'Nome percorso',
      'routeSaved': 'Percorso salvato',
      'profileHiking': 'Trekking',
      'profileTrailRun': 'Trail run',
      'profileWalking': 'Passeggiata',
      'profileMtb': 'MTB',
      'profileCycling': 'Bici',
      'profileDogWalk': 'Cane',
      'delete': 'Elimina',
      'deleteRoute': 'Eliminare il percorso?',
      'routingReady': 'Routing pronto',
      'routingCalculating': 'Calcolo percorso su sentieri e strade…',
      'routeSnapped': 'Percorso agganciato alla rete OSM',
      'routeLocalFallback': 'Modalità locale: linea diretta',
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
      'tapMapContinue': 'Tap the map to add more points',
      'pointsShort': 'pts',
      'waypoints': 'Points',
      'undo': 'Undo',
      'redo': 'Redo',
      'clear': 'Clear',
      'saveRoute': 'Save route',
      'save': 'Save',
      'cancel': 'Cancel',
      'route': 'Route',
      'routeName': 'Route name',
      'routeSaved': 'Route saved',
      'profileHiking': 'Hiking',
      'profileTrailRun': 'Trail run',
      'profileWalking': 'Walking',
      'profileMtb': 'MTB',
      'profileCycling': 'Cycling',
      'profileDogWalk': 'Dog walk',
      'delete': 'Delete',
      'deleteRoute': 'Delete route?',
      'routingReady': 'Routing ready',
      'routingCalculating': 'Routing along paths and roads…',
      'routeSnapped': 'Route snapped to the OSM network',
      'routeLocalFallback': 'Local mode: direct line',
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
      'tapMapContinue': 'Toca el mapa para añadir más puntos',
      'pointsShort': 'pts',
      'waypoints': 'Puntos',
      'undo': 'Deshacer',
      'redo': 'Rehacer',
      'clear': 'Limpiar',
      'saveRoute': 'Guardar ruta',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'route': 'Ruta',
      'routeName': 'Nombre de la ruta',
      'routeSaved': 'Ruta guardada',
      'profileHiking': 'Senderismo',
      'profileTrailRun': 'Trail run',
      'profileWalking': 'Paseo',
      'profileMtb': 'MTB',
      'profileCycling': 'Bici',
      'profileDogWalk': 'Perro',
      'delete': 'Eliminar',
      'deleteRoute': '¿Eliminar la ruta?',
      'routingReady': 'Routing listo',
      'routingCalculating': 'Calculando por caminos y carreteras…',
      'routeSnapped': 'Ruta ajustada a la red OSM',
      'routeLocalFallback': 'Modo local: línea directa',
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
      'tapMapContinue': 'Touchez la carte pour ajouter des points',
      'pointsShort': 'pts',
      'waypoints': 'Points',
      'undo': 'Annuler',
      'redo': 'Rétablir',
      'clear': 'Effacer',
      'saveRoute': 'Enregistrer',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'route': 'Parcours',
      'routeName': 'Nom du parcours',
      'routeSaved': 'Parcours enregistré',
      'profileHiking': 'Randonnée',
      'profileTrailRun': 'Trail',
      'profileWalking': 'Marche',
      'profileMtb': 'VTT',
      'profileCycling': 'Vélo',
      'profileDogWalk': 'Chien',
      'delete': 'Supprimer',
      'deleteRoute': 'Supprimer le parcours ?',
      'routingReady': 'Routage prêt',
      'routingCalculating': 'Calcul sur chemins et routes…',
      'routeSnapped': 'Parcours calé sur le réseau OSM',
      'routeLocalFallback': 'Mode local : ligne directe',
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
      'tapMapContinue': 'Toque no mapa para adicionar mais pontos',
      'pointsShort': 'pts',
      'waypoints': 'Pontos',
      'undo': 'Anular',
      'redo': 'Refazer',
      'clear': 'Limpar',
      'saveRoute': 'Guardar percurso',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'route': 'Percurso',
      'routeName': 'Nome do percurso',
      'routeSaved': 'Percurso guardado',
      'profileHiking': 'Caminhada',
      'profileTrailRun': 'Trail run',
      'profileWalking': 'Passeio',
      'profileMtb': 'MTB',
      'profileCycling': 'Bicicleta',
      'profileDogWalk': 'Cão',
      'delete': 'Eliminar',
      'deleteRoute': 'Eliminar percurso?',
      'routingReady': 'Roteamento pronto',
      'routingCalculating': 'A calcular por trilhos e estradas…',
      'routeSnapped': 'Percurso ajustado à rede OSM',
      'routeLocalFallback': 'Modo local: linha direta',
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
