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
  String get elevationProfile => _value('elevationProfile');
  String get elevation => _value('elevation');
  String get descent => _value('descent');
  String get grade => _value('grade');
  String get elevationLoading => _value('elevationLoading');
  String get elevationUnavailable => _value('elevationUnavailable');
  String get importGpx => _value('importGpx');
  String get shareGpx => _value('shareGpx');
  String get gpxImported => _value('gpxImported');
  String get gpxImportError => _value('gpxImportError');
  String get gpxExportError => _value('gpxExportError');
  String get recording => _value('recording');
  String get paused => _value('paused');
  String get pause => _value('pause');
  String get resume => _value('resume');
  String get finish => _value('finish');
  String get discard => _value('discard');
  String get recoveredRecording => _value('recoveredRecording');
  String get recoveredRecordingHint => _value('recoveredRecordingHint');
  String get activityName => _value('activityName');
  String get activitySaved => _value('activitySaved');
  String get activityTooShort => _value('activityTooShort');
  String get currentPace => _value('currentPace');
  String get gpsAccuracy => _value('gpsAccuracy');
  String get backgroundRecording => _value('backgroundRecording');
  String get yourActivities => _value('yourActivities');
  String get noActivities => _value('noActivities');
  String get noActivitiesHint => _value('noActivitiesHint');
  String get deleteActivity => _value('deleteActivity');
  String get navigate => _value('navigate');
  String get navigationActive => _value('navigationActive');
  String get offRoute => _value('offRoute');
  String get backOnRoute => _value('backOnRoute');
  String get arrived => _value('arrived');
  String get remainingDistance => _value('remainingDistance');
  String get routeProgress => _value('routeProgress');
  String get distanceFromRoute => _value('distanceFromRoute');
  String get backToRouteHint => _value('backToRouteHint');
  String get offline => _value('offline');
  String get offlineMaps => _value('offlineMaps');
  String get offlineHint => _value('offlineHint');
  String get downloadOffline => _value('downloadOffline');
  String get downloadingOffline => _value('downloadingOffline');
  String get offlineReady => _value('offlineReady');
  String get offlineFailed => _value('offlineFailed');
  String get offlineStorage => _value('offlineStorage');
  String get clearMapCache => _value('clearMapCache');
  String get cacheCleared => _value('cacheCleared');
  String get deleteOfflineMap => _value('deleteOfflineMap');
  String get noOfflineMaps => _value('noOfflineMaps');
  String get noOfflineMapsHint => _value('noOfflineMapsHint');
  String get storageUsed => _value('storageUsed');

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
      'elevationProfile': 'Profilo altimetrico',
      'elevation': 'Quota',
      'descent': 'Discesa',
      'grade': 'Pendenza',
      'elevationLoading': 'Calcolo quota e dislivello…',
      'elevationUnavailable': 'Profilo altimetrico non disponibile',
      'importGpx': 'Importa GPX',
      'shareGpx': 'Condividi GPX',
      'gpxImported': 'GPX importato',
      'gpxImportError': 'Impossibile importare questo GPX',
      'gpxExportError': 'Impossibile esportare il GPX',
      'recording': 'Registrazione in corso',
      'paused': 'Registrazione in pausa',
      'pause': 'Pausa',
      'resume': 'Riprendi',
      'finish': 'Termina',
      'discard': 'Scarta',
      'recoveredRecording': 'Registrazione recuperata',
      'recoveredRecordingHint': 'Ho trovato una registrazione interrotta. Puoi riprenderla o scartarla.',
      'activityName': 'Nome attività',
      'activitySaved': 'Attività salvata',
      'activityTooShort': 'Traccia troppo breve per essere salvata',
      'currentPace': 'Passo',
      'gpsAccuracy': 'Precisione GPS',
      'backgroundRecording': 'Registrazione GPS anche in background',
      'yourActivities': 'Le tue attività',
      'noActivities': 'Nessuna attività registrata',
      'noActivitiesHint': 'Le attività completate compariranno qui.',
      'deleteActivity': 'Eliminare l’attività?',
      'navigate': 'Naviga',
      'navigationActive': 'Navigazione attiva',
      'offRoute': 'Fuori percorso',
      'backOnRoute': 'Tornato sul percorso',
      'arrived': 'Arrivato',
      'remainingDistance': 'Rimanente',
      'routeProgress': 'Progresso',
      'distanceFromRoute': 'Dalla traccia',
      'backToRouteHint': 'Rientra verso la linea del percorso indicata sulla mappa.',
      'offline': 'Offline',
      'offlineMaps': 'Mappe offline',
      'offlineHint': 'Scarica la mappa di un percorso prima di partire: GPS e navigazione restano utilizzabili anche senza rete.',
      'downloadOffline': 'Scarica mappa',
      'downloadingOffline': 'Download mappa…',
      'offlineReady': 'Disponibile offline',
      'offlineFailed': 'Download offline non riuscito',
      'offlineStorage': 'Archivio offline',
      'clearMapCache': 'Svuota cache mappa',
      'cacheCleared': 'Cache mappa svuotata',
      'deleteOfflineMap': 'Eliminare la mappa offline?',
      'noOfflineMaps': 'Nessuna mappa offline',
      'noOfflineMapsHint': 'Apri Percorsi e scarica la mappa di un itinerario salvato.',
      'storageUsed': 'Spazio usato',
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
      'elevationProfile': 'Elevation profile',
      'elevation': 'Elevation',
      'descent': 'Descent',
      'grade': 'Grade',
      'elevationLoading': 'Calculating elevation and ascent…',
      'elevationUnavailable': 'Elevation profile unavailable',
      'importGpx': 'Import GPX',
      'shareGpx': 'Share GPX',
      'gpxImported': 'GPX imported',
      'gpxImportError': 'Could not import this GPX',
      'gpxExportError': 'Could not export GPX',
      'recording': 'Recording in progress',
      'paused': 'Recording paused',
      'pause': 'Pause',
      'resume': 'Resume',
      'finish': 'Finish',
      'discard': 'Discard',
      'recoveredRecording': 'Recovered recording',
      'recoveredRecordingHint': 'An interrupted recording was found. You can resume it or discard it.',
      'activityName': 'Activity name',
      'activitySaved': 'Activity saved',
      'activityTooShort': 'Track is too short to save',
      'currentPace': 'Pace',
      'gpsAccuracy': 'GPS accuracy',
      'backgroundRecording': 'GPS recording continues in background',
      'yourActivities': 'Your activities',
      'noActivities': 'No recorded activities',
      'noActivitiesHint': 'Completed activities will appear here.',
      'deleteActivity': 'Delete activity?',
      'navigate': 'Navigate',
      'navigationActive': 'Navigation active',
      'offRoute': 'Off route',
      'backOnRoute': 'Back on route',
      'arrived': 'Arrived',
      'remainingDistance': 'Remaining',
      'routeProgress': 'Progress',
      'distanceFromRoute': 'From route',
      'backToRouteHint': 'Head back toward the route line shown on the map.',
      'offline': 'Offline',
      'offlineMaps': 'Offline maps',
      'offlineHint': 'Download a saved route map before you leave: GPS and navigation keep working without a connection.',
      'downloadOffline': 'Download map',
      'downloadingOffline': 'Downloading map…',
      'offlineReady': 'Available offline',
      'offlineFailed': 'Offline download failed',
      'offlineStorage': 'Offline storage',
      'clearMapCache': 'Clear map cache',
      'cacheCleared': 'Map cache cleared',
      'deleteOfflineMap': 'Delete offline map?',
      'noOfflineMaps': 'No offline maps',
      'noOfflineMapsHint': 'Open Routes and download the map for a saved route.',
      'storageUsed': 'Storage used',
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
      'elevationProfile': 'Perfil de elevación',
      'elevation': 'Altitud',
      'descent': 'Descenso',
      'grade': 'Pendiente',
      'elevationLoading': 'Calculando altitud y desnivel…',
      'elevationUnavailable': 'Perfil de elevación no disponible',
      'importGpx': 'Importar GPX',
      'shareGpx': 'Compartir GPX',
      'gpxImported': 'GPX importado',
      'gpxImportError': 'No se pudo importar este GPX',
      'gpxExportError': 'No se pudo exportar el GPX',
      'recording': 'Registro en curso',
      'paused': 'Registro en pausa',
      'pause': 'Pausa',
      'resume': 'Reanudar',
      'finish': 'Finalizar',
      'discard': 'Descartar',
      'recoveredRecording': 'Registro recuperado',
      'recoveredRecordingHint': 'Se encontró un registro interrumpido. Puedes reanudarlo o descartarlo.',
      'activityName': 'Nombre de actividad',
      'activitySaved': 'Actividad guardada',
      'activityTooShort': 'La ruta es demasiado corta para guardarla',
      'currentPace': 'Ritmo',
      'gpsAccuracy': 'Precisión GPS',
      'backgroundRecording': 'El GPS continúa registrando en segundo plano',
      'yourActivities': 'Tus actividades',
      'noActivities': 'No hay actividades registradas',
      'noActivitiesHint': 'Las actividades completadas aparecerán aquí.',
      'deleteActivity': '¿Eliminar la actividad?',
      'navigate': 'Navegar',
      'navigationActive': 'Navegación activa',
      'offRoute': 'Fuera de ruta',
      'backOnRoute': 'De nuevo en ruta',
      'arrived': 'Has llegado',
      'remainingDistance': 'Restante',
      'routeProgress': 'Progreso',
      'distanceFromRoute': 'De la ruta',
      'backToRouteHint': 'Vuelve hacia la línea de ruta mostrada en el mapa.',
      'offline': 'Offline',
      'offlineMaps': 'Mapas offline',
      'offlineHint': 'Descarga el mapa de una ruta antes de salir: el GPS y la navegación siguen funcionando sin conexión.',
      'downloadOffline': 'Descargar mapa',
      'downloadingOffline': 'Descargando mapa…',
      'offlineReady': 'Disponible offline',
      'offlineFailed': 'Error al descargar el mapa offline',
      'offlineStorage': 'Almacenamiento offline',
      'clearMapCache': 'Vaciar caché del mapa',
      'cacheCleared': 'Caché del mapa vaciada',
      'deleteOfflineMap': '¿Eliminar mapa offline?',
      'noOfflineMaps': 'No hay mapas offline',
      'noOfflineMapsHint': 'Abre Rutas y descarga el mapa de una ruta guardada.',
      'storageUsed': 'Espacio usado',
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
      'elevationProfile': 'Profil altimétrique',
      'elevation': 'Altitude',
      'descent': 'Descente',
      'grade': 'Pente',
      'elevationLoading': 'Calcul de l’altitude et du dénivelé…',
      'elevationUnavailable': 'Profil altimétrique indisponible',
      'importGpx': 'Importer GPX',
      'shareGpx': 'Partager GPX',
      'gpxImported': 'GPX importé',
      'gpxImportError': 'Impossible d’importer ce GPX',
      'gpxExportError': 'Impossible d’exporter le GPX',
      'recording': 'Enregistrement en cours',
      'paused': 'Enregistrement en pause',
      'pause': 'Pause',
      'resume': 'Reprendre',
      'finish': 'Terminer',
      'discard': 'Supprimer',
      'recoveredRecording': 'Enregistrement récupéré',
      'recoveredRecordingHint': 'Un enregistrement interrompu a été trouvé. Vous pouvez le reprendre ou le supprimer.',
      'activityName': 'Nom de l’activité',
      'activitySaved': 'Activité enregistrée',
      'activityTooShort': 'Trace trop courte pour être enregistrée',
      'currentPace': 'Allure',
      'gpsAccuracy': 'Précision GPS',
      'backgroundRecording': 'Le GPS continue en arrière-plan',
      'yourActivities': 'Vos activités',
      'noActivities': 'Aucune activité enregistrée',
      'noActivitiesHint': 'Les activités terminées apparaîtront ici.',
      'deleteActivity': 'Supprimer l’activité ?',
      'navigate': 'Naviguer',
      'navigationActive': 'Navigation active',
      'offRoute': 'Hors parcours',
      'backOnRoute': 'De retour sur le parcours',
      'arrived': 'Arrivé',
      'remainingDistance': 'Restant',
      'routeProgress': 'Progression',
      'distanceFromRoute': 'Du parcours',
      'backToRouteHint': 'Revenez vers la ligne du parcours affichée sur la carte.',
      'offline': 'Hors ligne',
      'offlineMaps': 'Cartes hors ligne',
      'offlineHint': 'Téléchargez la carte d’un parcours avant de partir : le GPS et la navigation restent disponibles sans réseau.',
      'downloadOffline': 'Télécharger la carte',
      'downloadingOffline': 'Téléchargement…',
      'offlineReady': 'Disponible hors ligne',
      'offlineFailed': 'Échec du téléchargement hors ligne',
      'offlineStorage': 'Stockage hors ligne',
      'clearMapCache': 'Vider le cache de la carte',
      'cacheCleared': 'Cache de la carte vidé',
      'deleteOfflineMap': 'Supprimer la carte hors ligne ?',
      'noOfflineMaps': 'Aucune carte hors ligne',
      'noOfflineMapsHint': 'Ouvrez Parcours et téléchargez la carte d’un parcours enregistré.',
      'storageUsed': 'Espace utilisé',
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
      'elevationProfile': 'Perfil de elevação',
      'elevation': 'Altitude',
      'descent': 'Descida',
      'grade': 'Inclinação',
      'elevationLoading': 'A calcular altitude e desnível…',
      'elevationUnavailable': 'Perfil de elevação indisponível',
      'importGpx': 'Importar GPX',
      'shareGpx': 'Partilhar GPX',
      'gpxImported': 'GPX importado',
      'gpxImportError': 'Não foi possível importar este GPX',
      'gpxExportError': 'Não foi possível exportar o GPX',
      'recording': 'Gravação em curso',
      'paused': 'Gravação em pausa',
      'pause': 'Pausa',
      'resume': 'Retomar',
      'finish': 'Terminar',
      'discard': 'Descartar',
      'recoveredRecording': 'Gravação recuperada',
      'recoveredRecordingHint': 'Foi encontrada uma gravação interrompida. Pode retomá-la ou descartá-la.',
      'activityName': 'Nome da atividade',
      'activitySaved': 'Atividade guardada',
      'activityTooShort': 'Percurso demasiado curto para guardar',
      'currentPace': 'Ritmo',
      'gpsAccuracy': 'Precisão GPS',
      'backgroundRecording': 'A gravação GPS continua em segundo plano',
      'yourActivities': 'As suas atividades',
      'noActivities': 'Nenhuma atividade gravada',
      'noActivitiesHint': 'As atividades concluídas aparecerão aqui.',
      'deleteActivity': 'Eliminar atividade?',
      'navigate': 'Navegar',
      'navigationActive': 'Navegação ativa',
      'offRoute': 'Fora do percurso',
      'backOnRoute': 'De volta ao percurso',
      'arrived': 'Chegou',
      'remainingDistance': 'Restante',
      'routeProgress': 'Progresso',
      'distanceFromRoute': 'Do percurso',
      'backToRouteHint': 'Regresse à linha do percurso apresentada no mapa.',
      'offline': 'Offline',
      'offlineMaps': 'Mapas offline',
      'offlineHint': 'Descarregue o mapa de um percurso antes de sair: o GPS e a navegação continuam disponíveis sem rede.',
      'downloadOffline': 'Descarregar mapa',
      'downloadingOffline': 'A descarregar mapa…',
      'offlineReady': 'Disponível offline',
      'offlineFailed': 'Falha no download offline',
      'offlineStorage': 'Armazenamento offline',
      'clearMapCache': 'Limpar cache do mapa',
      'cacheCleared': 'Cache do mapa limpa',
      'deleteOfflineMap': 'Eliminar mapa offline?',
      'noOfflineMaps': 'Nenhum mapa offline',
      'noOfflineMapsHint': 'Abra Percursos e descarregue o mapa de um percurso guardado.',
      'storageUsed': 'Espaço usado',
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
