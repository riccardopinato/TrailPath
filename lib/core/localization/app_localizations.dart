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
  String get noSearchResults => _value('noSearchResults');
  String get searchFailed => _value('searchFailed');
  String get createRoute => _value('createRoute');
  String get tapMapHint => _value('tapMapHint');
  String get pointPreview => _value('pointPreview');
  String get startHere => _value('startHere');
  String get setDestination => _value('setDestination');
  String get addWaypoint => _value('addWaypoint');
  String get chooseDestination => _value('chooseDestination');
  String get chooseDestinationHint => _value('chooseDestinationHint');
  String get routeDetails => _value('routeDetails');
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
  String get mapOutdoor => _value('mapOutdoor');
  String get mapStreet => _value('mapStreet');
  String get mapHighContrast => _value('mapHighContrast');
  String get mapSatellite => _value('mapSatellite');
  String get mapHybrid => _value('mapHybrid');
  String get proMap => _value('proMap');
  String get proMapUnavailable => _value('proMapUnavailable');
  String get trailPathPro => _value('trailPathPro');
  String get proSubtitle => _value('proSubtitle');
  String get proActive => _value('proActive');
  String get proBenefitMaps => _value('proBenefitMaps');
  String get proBenefitTrace => _value('proBenefitTrace');
  String get proBenefitOffline => _value('proBenefitOffline');
  String get proBenefitStats => _value('proBenefitStats');
  String get proBenefitCloud => _value('proBenefitCloud');
  String get proMonthly => _value('proMonthly');
  String get proYearly => _value('proYearly');
  String get proMonthlyUnavailable => _value('proMonthlyUnavailable');
  String get proYearlyUnavailable => _value('proYearlyUnavailable');
  String get restorePurchases => _value('restorePurchases');
  String get proStoreUnavailable => _value('proStoreUnavailable');
  String get proPurchaseError => _value('proPurchaseError');
  String get proSafetyFree => _value('proSafetyFree');
  String get proRenewalNotice => _value('proRenewalNotice');
  String get profile => _value('profile');
  String get settings => _value('settings');
  String get preferences => _value('preferences');
  String get activitySummary => _value('activitySummary');
  String get activities => _value('activities');
  String get totalDistance => _value('totalDistance');
  String get totalAscent => _value('totalAscent');
  String get savedRoutesCount => _value('savedRoutesCount');
  String get outdoorTools => _value('outdoorTools');
  String get cloudSync => _value('cloudSync');
  String get cloudSyncAccountHint => _value('cloudSyncAccountHint');
  String get syncNow => _value('syncNow');
  String get syncing => _value('syncing');
  String get syncLast => _value('syncLast');
  String get syncPending => _value('syncPending');
  String get syncRequiresPro => _value('syncRequiresPro');
  String get syncRequiresAccount => _value('syncRequiresAccount');
  String get syncUnavailable => _value('syncUnavailable');
  String get syncReady => _value('syncReady');
  String get syncDone => _value('syncDone');
  String get syncError => _value('syncError');
  String get googleAccount => _value('googleAccount');
  String get signInGoogle => _value('signInGoogle');
  String get signOut => _value('signOut');
  String get accountOptional => _value('accountOptional');
  String get accountNotConfigured => _value('accountNotConfigured');
  String get appearance => _value('appearance');
  String get theme => _value('theme');
  String get systemTheme => _value('systemTheme');
  String get lightTheme => _value('lightTheme');
  String get darkTheme => _value('darkTheme');
  String get routePreferences => _value('routePreferences');
  String get defaultActivity => _value('defaultActivity');
  String get defaultMap => _value('defaultMap');
  String get units => _value('units');
  String get metricUnits => _value('metricUnits');
  String get imperialUnits => _value('imperialUnits');
  String get gpsAndDownloads => _value('gpsAndDownloads');
  String get voiceGuidance => _value('voiceGuidance');
  String get voiceGuidanceHint => _value('voiceGuidanceHint');
  String get wifiOnlyDownloads => _value('wifiOnlyDownloads');
  String get wifiOnlyDownloadsHint => _value('wifiOnlyDownloadsHint');
  String get privacyData => _value('privacyData');
  String get localFirst => _value('localFirst');
  String get localFirstHint => _value('localFirstHint');
  String get routeLab => _value('routeLab');
  String get routeLabHint => _value('routeLabHint');
  String get circularRoute => _value('circularRoute');
  String get circularRouteHint => _value('circularRouteHint');
  String get generateRoutes => _value('generateRoutes');
  String get routeOption => _value('routeOption');
  String get routeAlternatives => _value('routeAlternatives');
  String get routeAlternativesUnavailable =>
      _value('routeAlternativesUnavailable');
  String get shortestRoute => _value('shortestRoute');
  String get leastClimb => _value('leastClimb');
  String get moreTrail => _value('moreTrail');
  String get moreRoad => _value('moreRoad');
  String get generateAlternatives => _value('generateAlternatives');
  String get alternative => _value('alternative');
  String get routeContext => _value('routeContext');
  String get routeContextHint => _value('routeContextHint');
  String get analyzeRoute => _value('analyzeRoute');
  String get surface => _value('surface');
  String get weatherAlongRoute => _value('weatherAlongRoute');
  String get outdoorPois => _value('outdoorPois');
  String get fromRoute => _value('fromRoute');
  String get noRouteCandidates => _value('noRouteCandidates');
  String get routeGenerationFailed => _value('routeGenerationFailed');
  String get routeContextFailed => _value('routeContextFailed');
  String get surfacePaved => _value('surfacePaved');
  String get surfaceGravel => _value('surfaceGravel');
  String get surfaceDirt => _value('surfaceDirt');
  String get surfaceTrail => _value('surfaceTrail');
  String get surfaceUnknown => _value('surfaceUnknown');
  String get routeCollections => _value('routeCollections');
  String get routeCollectionsHint => _value('routeCollectionsHint');
  String get newCollection => _value('newCollection');
  String get collectionName => _value('collectionName');
  String get collectionsUnavailable => _value('collectionsUnavailable');
  String get noCollections => _value('noCollections');
  String get noCollectionsHint => _value('noCollectionsHint');
  String get manageCollection => _value('manageCollection');
  String get deleteCollection => _value('deleteCollection');
  String get personalStats => _value('personalStats');
  String get personalStatsHint => _value('personalStatsHint');
  String get statsUnavailable => _value('statsUnavailable');
  String get last7Days => _value('last7Days');
  String get last30Days => _value('last30Days');
  String get longestActivity => _value('longestActivity');
  String get highestAscent => _value('highestAscent');
  String get movingTime => _value('movingTime');
  String get slopeMap => _value('slopeMap');
  String get slopeMapHint => _value('slopeMapHint');
  String get terrain3d => _value('terrain3d');
  String get terrain3dHint => _value('terrain3dHint');
  String get autoReroute => _value('autoReroute');
  String get autoRerouteHint => _value('autoRerouteHint');
  String get autoRerouteProHint => _value('autoRerouteProHint');
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
  String get routeDeleteFailed => _value('routeDeleteFailed');
  String get routingReady => _value('routingReady');
  String get routingCalculating => _value('routingCalculating');
  String get routeSnapped => _value('routeSnapped');
  String get routeUnavailable => _value('routeUnavailable');
  String get routeNetworkUnavailable => _value('routeNetworkUnavailable');
  String get routeTimeout => _value('routeTimeout');
  String get routeRateLimited => _value('routeRateLimited');
  String get routeNoPath => _value('routeNoPath');
  String get routeProviderUnavailable => _value('routeProviderUnavailable');
  String get routeInvalidResponse => _value('routeInvalidResponse');
  String get routeLocalFallback => _value('routeLocalFallback');
  String get routeEditHint => _value('routeEditHint');
  String get routeEditActive => _value('routeEditActive');
  String get routeDragActive => _value('routeDragActive');
  String get traceMode => _value('traceMode');
  String get traceFollowTrails => _value('traceFollowTrails');
  String get traceFollowRoads => _value('traceFollowRoads');
  String get traceFree => _value('traceFree');
  String get traceCloseLoop => _value('traceCloseLoop');
  String get traceOutAndBack => _value('traceOutAndBack');
  String get traceReverse => _value('traceReverse');
  String get traceErase => _value('traceErase');
  String get traceHint => _value('traceHint');
  String get traceDrawing => _value('traceDrawing');
  String get traceProcessing => _value('traceProcessing');
  String get traceTooShort => _value('traceTooShort');
  String get traceFailed => _value('traceFailed');
  String get routePressTooFar => _value('routePressTooFar');
  String get waypointSelected => _value('waypointSelected');
  String get removeWaypoint => _value('removeWaypoint');
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
  String get activitySaveFailed => _value('activitySaveFailed');
  String get retrySave => _value('retrySave');
  String get savePending => _value('savePending');
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
  String get outdoor => _value('outdoor');
  String get outdoorHint => _value('outdoorHint');
  String get batteryMode => _value('batteryMode');
  String get batteryPerformance => _value('batteryPerformance');
  String get batteryBalanced => _value('batteryBalanced');
  String get batterySaver => _value('batterySaver');
  String get batteryPerformanceHint => _value('batteryPerformanceHint');
  String get batteryBalancedHint => _value('batteryBalancedHint');
  String get batterySaverHint => _value('batterySaverHint');
  String get backToCar => _value('backToCar');
  String get backToCarHint => _value('backToCarHint');
  String get saveCarHere => _value('saveCarHere');
  String get updateCarPosition => _value('updateCarPosition');
  String get carPositionSaved => _value('carPositionSaved');
  String get carSavedAt => _value('carSavedAt');
  String get openBackToCar => _value('openBackToCar');
  String get clearCar => _value('clearCar');
  String get clearCarHint => _value('clearCarHint');
  String get safetyCheck => _value('safetyCheck');
  String get safetyCheckHint => _value('safetyCheckHint');
  String get refresh => _value('refresh');
  String get battery => _value('battery');
  String get systemBatterySaver => _value('systemBatterySaver');
  String get gpsPermission => _value('gpsPermission');
  String get locationServices => _value('locationServices');
  String get offlineMap => _value('offlineMap');
  String get sharePosition => _value('sharePosition');
  String get sharePositionHint => _value('sharePositionHint');
  String get sharedPositionMessage => _value('sharedPositionMessage');
  String get sharePositionError => _value('sharePositionError');
  String get distanceToCar => _value('distanceToCar');
  String get direction => _value('direction');
  String get waitingForGps => _value('waitingForGps');
  String get gpsEvery => _value('gpsEvery');

  String get onboardingTitle => _value('onboardingTitle');
  String get onboardingIntro => _value('onboardingIntro');
  String get onboardingPlanTitle => _value('onboardingPlanTitle');
  String get onboardingPlanBody => _value('onboardingPlanBody');
  String get onboardingOfflineTitle => _value('onboardingOfflineTitle');
  String get onboardingOfflineBody => _value('onboardingOfflineBody');
  String get onboardingRecordTitle => _value('onboardingRecordTitle');
  String get onboardingRecordBody => _value('onboardingRecordBody');
  String get onboardingPrivacy => _value('onboardingPrivacy');
  String get onboardingStart => _value('onboardingStart');

  static const Map<String, Map<String, String>> _values = {
    'it': {
      'onboardingTitle': 'Prima di partire',
      'onboardingIntro': 'TrailPath ti aiuta a pianificare, registrare e seguire percorsi outdoor anche quando la rete manca.',
      'onboardingPlanTitle': 'Pianifica su sentieri e strade',
      'onboardingPlanBody': 'Tocca la mappa, cerca un luogo o disegna la traccia. Il percorso viene agganciato alla rete OSM quando disponibile.',
      'onboardingOfflineTitle': 'Prepara la mappa offline',
      'onboardingOfflineBody': 'Scarica la zona del percorso prima di uscire: la mappa preparata e la navigazione restano disponibili senza rete.',
      'onboardingRecordTitle': 'Registra e naviga',
      'onboardingRecordBody': 'Usa il GPS per registrare l’attività, seguire percorsi salvati e ritrovare il punto auto.',
      'onboardingPrivacy': 'Percorsi e attività restano sul dispositivo. TrailPath chiede la posizione solo quando serve a una funzione GPS.',
      'onboardingStart': 'Inizia con TrailPath',
      'planner': 'Pianifica',
      'record': 'Registra',
      'routes': 'Percorsi',
      'searchPlace': 'Cerca luogo o sentiero',
      'noSearchResults': 'Nessun risultato trovato',
      'searchFailed': 'Ricerca non disponibile. Riprova più tardi',
      'createRoute': 'Crea un percorso',
      'pointPreview': 'Punto selezionato',
      'startHere': 'Parti da qui',
      'setDestination': 'Destinazione',
      'addWaypoint': 'Aggiungi tappa',
      'chooseDestination': 'Scegli la destinazione',
      'chooseDestinationHint': 'Tocca la mappa o cerca un luogo',
      'routeDetails': 'Dettagli percorso',
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
      'mapOutdoor': 'Outdoor',
      'mapStreet': 'Stradale',
      'mapHighContrast': 'Alto contrasto',
      'mapSatellite': 'Satellite',
      'mapHybrid': 'Satellite + strade',
      'proMap': 'Mappa Pro',
      'proMapUnavailable': 'Mappa Pro non configurata',
      'trailPathPro': 'TrailPath Pro',
      'proSubtitle': 'Mappe e strumenti outdoor avanzati',
      'proActive': 'TrailPath Pro attivo',
      'proBenefitMaps': 'Satellite e mappe premium',
      'proBenefitTrace': 'Smart Trace e strumenti percorso avanzati',
      'proBenefitOffline': 'Funzioni offline avanzate',
      'proBenefitStats': 'Statistiche e analisi avanzate',
      'proBenefitCloud': 'Cloud sync e backup tra dispositivi',
      'proMonthly': 'Mensile',
      'proYearly': 'Annuale',
      'proMonthlyUnavailable': 'Piano mensile non configurato',
      'proYearlyUnavailable': 'Piano annuale non configurato',
      'restorePurchases': 'Ripristina acquisti',
      'proStoreUnavailable': 'Google Play Billing non è disponibile o i prodotti Pro non sono ancora configurati.',
      'proPurchaseError': 'Non è stato possibile completare l\'acquisto.',
      'proSafetyFree': 'Registrazione, recovery e funzioni di sicurezza di base restano disponibili anche senza Pro.',
      'proRenewalNotice': 'L’abbonamento si rinnova automaticamente al periodo selezionato finché non viene annullato da Google Play.',
      'profile': 'Profilo',
      'settings': 'Impostazioni',
      'preferences': 'Preferenze dell\'app',
      'activitySummary': 'Riepilogo attività',
      'activities': 'Attività',
      'totalDistance': 'Distanza totale',
      'totalAscent': 'Dislivello totale',
      'savedRoutesCount': 'Percorsi salvati',
      'outdoorTools': 'Strumenti Outdoor',
      'cloudSync': 'Cloud Sync',
      'cloudSyncAccountHint': 'Backup e sincronizzazione opzionali con account',
      'syncNow': 'Sincronizza ora',
      'syncing': 'Sincronizzazione…',
      'syncLast': 'Ultima sincronizzazione',
      'syncPending': 'modifiche in attesa',
      'syncRequiresPro': 'Richiede TrailPath Pro',
      'syncRequiresAccount': 'Accedi con Google per sincronizzare',
      'syncUnavailable': 'Cloud Sync non configurato in questa build',
      'syncReady': 'Pronto per la sincronizzazione',
      'syncDone': 'Sincronizzazione completata',
      'syncError': 'Errore di sincronizzazione',
      'googleAccount': 'Account Google',
      'signInGoogle': 'Accedi',
      'signOut': 'Esci',
      'accountOptional': 'Account facoltativo: TrailPath funziona anche offline e senza login.',
      'accountNotConfigured': 'Google Sign-In non configurato in questa build.',
      'appearance': 'Aspetto',
      'theme': 'Tema',
      'systemTheme': 'Sistema',
      'lightTheme': 'Chiaro',
      'darkTheme': 'Scuro',
      'routePreferences': 'Preferenze percorso',
      'defaultActivity': 'Attività predefinita',
      'defaultMap': 'Mappa predefinita',
      'units': 'Unità',
      'metricUnits': 'Metriche (km, m)',
      'imperialUnits': 'Imperiali (mi, ft)',
      'gpsAndDownloads': 'GPS e download',
      'voiceGuidance': 'Guida vocale',
      'voiceGuidanceHint': 'Usa la voce durante la navigazione attiva.',
      'wifiOnlyDownloads': 'Download mappe solo Wi‑Fi',
      'wifiOnlyDownloadsHint':
          'Evita di avviare nuovi download offline su rete mobile.',
      'privacyData': 'Privacy e dati',
      'localFirst': 'Local-first',
      'localFirstHint': 'Percorsi e attività restano sul dispositivo salvo sincronizzazione cloud esplicitamente attivata.',
      'routeLab': 'Route Lab',
      'routeLabHint':
          'Anelli, alternative, POI, meteo e superficie del percorso',
      'circularRoute': 'Percorso circolare',
      'circularRouteHint': 'Genera anelli reali sulle strade e sui sentieri OSM partendo dalla posizione attuale.',
      'generateRoutes': 'Genera percorsi',
      'routeOption': 'Opzione',
      'routeAlternatives': 'Percorsi alternativi',
      'routeAlternativesUnavailable':
          'Alternative temporaneamente non disponibili',
      'shortestRoute': 'Più breve',
      'leastClimb': 'Meno salita',
      'moreTrail': 'Più sentieri',
      'moreRoad': 'Più strada',
      'generateAlternatives': 'Genera alternative',
      'alternative': 'Alternativa',
      'routeContext': 'Contesto del percorso',
      'routeContextHint':
          'Analizza POI outdoor, meteo e superficie lungo un percorso salvato.',
      'analyzeRoute': 'Analizza percorso',
      'surface': 'Superficie',
      'weatherAlongRoute': 'Meteo lungo il percorso',
      'outdoorPois': 'POI outdoor',
      'fromRoute': 'dal percorso',
      'noRouteCandidates':
          'Nessun percorso valido trovato per questi parametri.',
      'routeGenerationFailed': 'Impossibile generare i percorsi.',
      'routeContextFailed': 'Impossibile analizzare il contesto del percorso.',
      'surfacePaved': 'Asfalto/pavimentato',
      'surfaceGravel': 'Ghiaia/compatto',
      'surfaceDirt': 'Terra',
      'surfaceTrail': 'Sentiero/sterrato',
      'surfaceUnknown': 'Sconosciuta',
      'routeCollections': 'Collezioni',
      'routeCollectionsHint': 'Organizza i percorsi in cartelle personali',
      'newCollection': 'Nuova collezione',
      'collectionName': 'Nome collezione',
      'collectionsUnavailable': 'Collezioni temporaneamente non disponibili',
      'noCollections': 'Nessuna collezione',
      'noCollectionsHint':
          'Crea cartelle per organizzare percorsi, viaggi e attività.',
      'manageCollection': 'Gestisci percorsi',
      'deleteCollection': 'Eliminare la collezione?',
      'personalStats': 'Statistiche',
      'personalStatsHint': 'Analizza distanza, dislivello e attività nel tempo',
      'statsUnavailable': 'Statistiche temporaneamente non disponibili',
      'last7Days': 'Ultimi 7 giorni',
      'last30Days': 'Ultimi 30 giorni',
      'longestActivity': 'Attività più lunga',
      'highestAscent': 'Dislivello massimo',
      'movingTime': 'Tempo in movimento',
      'slopeMap': 'Mappa pendenza',
      'slopeMapHint': 'Colora il percorso in base alla pendenza',
      'terrain3d': 'Terreno 3D',
      'terrain3dHint': 'Rilievo 3D basato sui dati altimetrici della mappa',
      'autoReroute': 'Ricalcolo automatico',
      'autoRerouteHint': 'Calcola un nuovo percorso verso la destinazione quando esci dalla traccia.',
      'autoRerouteProHint':
          'Ricalcolo automatico disponibile con TrailPath Pro.',
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
      'routeDeleteFailed': 'Impossibile eliminare completamente il percorso',
      'routingReady': 'Routing pronto',
      'routingCalculating': 'Calcolo percorso su sentieri e strade…',
      'routeSnapped': 'Percorso agganciato alla rete OSM',
      'routeUnavailable': 'Routing non disponibile: modifica i punti o riprova',
      'routeNetworkUnavailable': 'Nessuna connessione: impossibile calcolare il percorso',
      'routeTimeout': 'Il routing sta impiegando troppo tempo: riprova',
      'routeRateLimited': 'Servizio routing temporaneamente occupato: riprova tra poco',
      'routeNoPath': 'Nessun percorso valido trovato tra questi punti',
      'routeProviderUnavailable': 'Servizio routing temporaneamente non disponibile',
      'routeInvalidResponse': 'Risposta routing non valida: riprova',
      'routeLocalFallback': 'Percorso locale o GPX non agganciato alla rete',
      'routeEditHint':
          'Tocca la linea per modificarla; trascina i punti per spostarli.',
      'routeEditActive': 'Modifica attiva: trascina i punti bianchi tra le tappe per inserirne di nuovi.',
      'routeDragActive': 'Spostamento in corso: rilascia per ricalcolare solo il tratto modificato.',
      'traceMode': 'Disegna percorso',
      'traceFollowTrails': 'Segui sentieri',
      'traceFollowRoads': 'Segui strade',
      'traceFree': 'Libero',
      'traceCloseLoop': 'Chiudi anello',
      'traceOutAndBack': 'Andata e ritorno',
      'traceReverse': 'Inverti',
      'traceErase': 'Gomma ultimo tratto',
      'traceHint': 'Modalità Disegna: trascina il dito sulla mappa per seguire il sentiero desiderato.',
      'traceDrawing': 'Continua a disegnare; al rilascio TrailPath aggancerà il tratto alla rete OSM.',
      'traceProcessing': 'Conversione del gesto in percorso reale…',
      'traceTooShort': 'Disegna un tratto un po’ più lungo.',
      'traceFailed': 'Impossibile convertire il gesto in un percorso.',
      'routePressTooFar': 'Tieni premuto più vicino alla linea del percorso.',
      'waypointSelected': 'Punto selezionato',
      'removeWaypoint': 'Rimuovi',
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
      'activitySaveFailed': 'Salvataggio attività non riuscito. La traccia è ancora recuperabile.',
      'retrySave': 'Riprova salvataggio',
      'savePending': 'Salvataggio in attesa',
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
      'backToRouteHint':
          'Rientra verso la linea del percorso indicata sulla mappa.',
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
      'noOfflineMapsHint':
          'Apri Percorsi e scarica la mappa di un itinerario salvato.',
      'storageUsed': 'Spazio usato',
      'outdoor': 'Outdoor',
      'outdoorHint':
          'Strumenti rapidi per autonomia, rientro e sicurezza sul sentiero.',
      'batteryMode': 'Modalità batteria',
      'batteryPerformance': 'Prestazioni',
      'batteryBalanced': 'Bilanciata',
      'batterySaver': 'Risparmio',
      'batteryPerformanceHint': 'GPS più frequente e preciso, ideale per trail e navigazione impegnativa.',
      'batteryBalancedHint': 'Equilibrio tra precisione GPS e autonomia per la maggior parte delle uscite.',
      'batterySaverHint':
          'Riduce gli aggiornamenti GPS per prolungare l’autonomia.',
      'backToCar': 'Back to Car',
      'backToCarHint':
          'Salva il punto di parcheggio e ritrovalo anche senza rete.',
      'saveCarHere': 'Salva auto qui',
      'updateCarPosition': 'Aggiorna posizione',
      'carPositionSaved': 'Posizione auto salvata',
      'carSavedAt': 'Salvata',
      'openBackToCar': 'Apri Back to Car',
      'clearCar': 'Rimuovi posizione auto',
      'clearCarHint': 'Il punto salvato verrà eliminato.',
      'safetyCheck': 'Safety Check',
      'safetyCheckHint':
          'Controlla batteria, GPS, permessi e mappe offline prima di partire.',
      'refresh': 'Aggiorna',
      'battery': 'Batteria',
      'systemBatterySaver': 'Risparmio sistema',
      'gpsPermission': 'Permesso GPS',
      'locationServices': 'Servizi posizione',
      'offlineMap': 'Mappa offline',
      'sharePosition': 'Condividi posizione',
      'sharePositionHint': 'Condividi le coordinate correnti con un contatto.',
      'sharedPositionMessage': 'La mia posizione da TrailPath',
      'sharePositionError': 'Impossibile condividere la posizione',
      'distanceToCar': 'Distanza dall’auto',
      'direction': 'Direzione',
      'waitingForGps': 'In attesa del GPS',
      'gpsEvery': 'Aggiornamento GPS ogni',
    },
    'en': {
      'onboardingTitle': 'Before you head out',
      'onboardingIntro': 'TrailPath helps you plan, record and follow outdoor routes, including when connectivity disappears.',
      'onboardingPlanTitle': 'Plan on paths and roads',
      'onboardingPlanBody': 'Tap the map, search for a place or draw a trace. TrailPath snaps the route to the OSM network when available.',
      'onboardingOfflineTitle': 'Prepare an offline map',
      'onboardingOfflineBody': 'Download the route area before you leave so the prepared map and saved-route navigation remain useful without a network.',
      'onboardingRecordTitle': 'Record and navigate',
      'onboardingRecordBody': 'Use GPS to record an activity, follow saved routes and return to a saved car position.',
      'onboardingPrivacy': 'Routes and activities stay on this device. TrailPath asks for location only when a GPS feature needs it.',
      'onboardingStart': 'Start TrailPath',
      'planner': 'Plan',
      'record': 'Record',
      'routes': 'Routes',
      'searchPlace': 'Search place or trail',
      'noSearchResults': 'No results found',
      'searchFailed': 'Search is unavailable. Try again later',
      'createRoute': 'Create a route',
      'pointPreview': 'Selected point',
      'startHere': 'Start here',
      'setDestination': 'Destination',
      'addWaypoint': 'Add waypoint',
      'chooseDestination': 'Choose destination',
      'chooseDestinationHint': 'Tap the map or search for a place',
      'routeDetails': 'Route details',
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
      'mapOutdoor': 'Outdoor',
      'mapStreet': 'Street',
      'mapHighContrast': 'High contrast',
      'mapSatellite': 'Satellite',
      'mapHybrid': 'Satellite + roads',
      'proMap': 'Pro map',
      'proMapUnavailable': 'Pro map provider not configured',
      'trailPathPro': 'TrailPath Pro',
      'proSubtitle': 'Advanced maps and outdoor tools',
      'proActive': 'TrailPath Pro active',
      'proBenefitMaps': 'Satellite and premium maps',
      'proBenefitTrace': 'Advanced Smart Trace and route tools',
      'proBenefitOffline': 'Advanced offline features',
      'proBenefitStats': 'Advanced statistics and analysis',
      'proBenefitCloud': 'Cloud sync and cross-device backup',
      'proMonthly': 'Monthly',
      'proYearly': 'Yearly',
      'proMonthlyUnavailable': 'Monthly plan not configured',
      'proYearlyUnavailable': 'Yearly plan not configured',
      'restorePurchases': 'Restore purchases',
      'proStoreUnavailable': 'Google Play Billing is unavailable or Pro products are not configured yet.',
      'proPurchaseError': 'The purchase could not be completed.',
      'proSafetyFree': 'Core recording, recovery and safety features remain available without Pro.',
      'proRenewalNotice': 'The subscription renews automatically for the selected period until cancelled through Google Play.',
      'profile': 'Profile',
      'settings': 'Settings',
      'preferences': 'App preferences',
      'activitySummary': 'Activity summary',
      'activities': 'Activities',
      'totalDistance': 'Total distance',
      'totalAscent': 'Total ascent',
      'savedRoutesCount': 'Saved routes',
      'outdoorTools': 'Outdoor tools',
      'cloudSync': 'Cloud Sync',
      'cloudSyncAccountHint': 'Optional backup and sync with an account',
      'syncNow': 'Sync now',
      'syncing': 'Syncing…',
      'syncLast': 'Last sync',
      'syncPending': 'pending changes',
      'syncRequiresPro': 'Requires TrailPath Pro',
      'syncRequiresAccount': 'Sign in with Google to sync',
      'syncUnavailable': 'Cloud Sync is not configured in this build',
      'syncReady': 'Ready to sync',
      'syncDone': 'Sync complete',
      'syncError': 'Sync error',
      'googleAccount': 'Google account',
      'signInGoogle': 'Sign in',
      'signOut': 'Sign out',
      'accountOptional':
          'Account is optional: TrailPath works offline and without sign-in.',
      'accountNotConfigured': 'Google Sign-In is not configured in this build.',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'systemTheme': 'System',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'routePreferences': 'Route preferences',
      'defaultActivity': 'Default activity',
      'defaultMap': 'Default map',
      'units': 'Units',
      'metricUnits': 'Metric (km, m)',
      'imperialUnits': 'Imperial (mi, ft)',
      'gpsAndDownloads': 'GPS and downloads',
      'voiceGuidance': 'Voice guidance',
      'voiceGuidanceHint': 'Use spoken feedback during active navigation.',
      'wifiOnlyDownloads': 'Offline maps on Wi‑Fi only',
      'wifiOnlyDownloadsHint':
          'Do not start new offline downloads on mobile data.',
      'privacyData': 'Privacy and data',
      'localFirst': 'Local-first',
      'localFirstHint': 'Routes and activities stay on this device unless cloud sync is explicitly enabled.',
      'routeLab': 'Route Lab',
      'routeLabHint': 'Loops, alternatives, POIs, weather and route surface',
      'circularRoute': 'Circular route',
      'circularRouteHint': 'Generate real loops on OSM roads and trails from your current position.',
      'generateRoutes': 'Generate routes',
      'routeOption': 'Option',
      'routeAlternatives': 'Route alternatives',
      'routeAlternativesUnavailable':
          'Alternatives are temporarily unavailable',
      'shortestRoute': 'Shortest',
      'leastClimb': 'Less climbing',
      'moreTrail': 'More trail',
      'moreRoad': 'More road',
      'generateAlternatives': 'Generate alternatives',
      'alternative': 'Alternative',
      'routeContext': 'Route context',
      'routeContextHint':
          'Analyze outdoor POIs, weather and surface along a saved route.',
      'analyzeRoute': 'Analyze route',
      'surface': 'Surface',
      'weatherAlongRoute': 'Weather along route',
      'outdoorPois': 'Outdoor POIs',
      'fromRoute': 'from route',
      'noRouteCandidates': 'No valid route found for these parameters.',
      'routeGenerationFailed': 'Routes could not be generated.',
      'routeContextFailed': 'Route context could not be analyzed.',
      'surfacePaved': 'Paved',
      'surfaceGravel': 'Gravel/compacted',
      'surfaceDirt': 'Dirt',
      'surfaceTrail': 'Trail/unpaved',
      'surfaceUnknown': 'Unknown',
      'routeCollections': 'Collections',
      'routeCollectionsHint': 'Organize routes into personal folders',
      'newCollection': 'New collection',
      'collectionName': 'Collection name',
      'collectionsUnavailable': 'Collections are temporarily unavailable',
      'noCollections': 'No collections',
      'noCollectionsHint':
          'Create folders to organize routes, trips and activities.',
      'manageCollection': 'Manage routes',
      'deleteCollection': 'Delete collection?',
      'personalStats': 'Statistics',
      'personalStatsHint': 'Analyze distance, ascent and activity over time',
      'statsUnavailable': 'Statistics are temporarily unavailable',
      'last7Days': 'Last 7 days',
      'last30Days': 'Last 30 days',
      'longestActivity': 'Longest activity',
      'highestAscent': 'Highest ascent',
      'movingTime': 'Moving time',
      'slopeMap': 'Slope map',
      'slopeMapHint': 'Color the route by grade',
      'terrain3d': '3D terrain',
      'terrain3dHint': '3D relief using map elevation data',
      'autoReroute': 'Automatic rerouting',
      'autoRerouteHint':
          'Calculate a new route to the destination when you leave the track.',
      'autoRerouteProHint':
          'Automatic rerouting is available with TrailPath Pro.',
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
      'routeDeleteFailed': 'Could not completely delete the route',
      'routingReady': 'Routing ready',
      'routingCalculating': 'Routing along paths and roads…',
      'routeSnapped': 'Route snapped to the OSM network',
      'routeUnavailable': 'Routing unavailable: adjust the points or try again',
      'routeNetworkUnavailable': 'No connection: the route cannot be calculated',
      'routeTimeout': 'Routing is taking too long: try again',
      'routeRateLimited': 'Routing service is temporarily busy: try again shortly',
      'routeNoPath': 'No valid route was found between these points',
      'routeProviderUnavailable': 'Routing service is temporarily unavailable',
      'routeInvalidResponse': 'Invalid routing response: try again',
      'routeLocalFallback': 'Local or GPX route not snapped to the network',
      'routeEditHint':
          'Tap the route line to edit it; drag points to move them.',
      'routeEditActive': 'Edit mode: drag the white points between waypoints to insert new ones.',
      'routeDragActive':
          'Dragging: release to recalculate only the edited span.',
      'traceMode': 'Draw route',
      'traceFollowTrails': 'Follow trails',
      'traceFollowRoads': 'Follow roads',
      'traceFree': 'Free',
      'traceCloseLoop': 'Close loop',
      'traceOutAndBack': 'Out & back',
      'traceReverse': 'Reverse',
      'traceErase': 'Erase last segment',
      'traceHint': 'Draw mode: drag your finger over the map along the path you want to follow.',
      'traceDrawing': 'Keep drawing; on release TrailPath will snap the trace to the OSM network.',
      'traceProcessing': 'Turning your gesture into a real route…',
      'traceTooShort': 'Draw a slightly longer segment.',
      'traceFailed': 'Could not turn the gesture into a route.',
      'routePressTooFar': 'Long-press closer to the route line.',
      'waypointSelected': 'Selected point',
      'removeWaypoint': 'Remove',
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
      'activitySaveFailed':
          'Activity save failed. Your track is still recoverable.',
      'retrySave': 'Retry save',
      'savePending': 'Save pending',
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
      'noOfflineMapsHint':
          'Open Routes and download the map for a saved route.',
      'storageUsed': 'Storage used',
      'outdoor': 'Outdoor',
      'outdoorHint':
          'Quick tools for battery life, return guidance and trail safety.',
      'batteryMode': 'Battery mode',
      'batteryPerformance': 'Performance',
      'batteryBalanced': 'Balanced',
      'batterySaver': 'Saver',
      'batteryPerformanceHint':
          'More frequent, precise GPS for demanding trails and navigation.',
      'batteryBalancedHint':
          'Balances GPS precision and battery life for most outings.',
      'batterySaverHint': 'Reduces GPS updates to extend battery life.',
      'backToCar': 'Back to Car',
      'backToCarHint': 'Save your parking point and find it again even without a connection.',
      'saveCarHere': 'Save car here',
      'updateCarPosition': 'Update position',
      'carPositionSaved': 'Car position saved',
      'carSavedAt': 'Saved',
      'openBackToCar': 'Open Back to Car',
      'clearCar': 'Remove car position',
      'clearCarHint': 'The saved return point will be deleted.',
      'safetyCheck': 'Safety Check',
      'safetyCheckHint':
          'Check battery, GPS, permissions and offline maps before leaving.',
      'refresh': 'Refresh',
      'battery': 'Battery',
      'systemBatterySaver': 'System saver',
      'gpsPermission': 'GPS permission',
      'locationServices': 'Location services',
      'offlineMap': 'Offline map',
      'sharePosition': 'Share position',
      'sharePositionHint': 'Share your current coordinates with a contact.',
      'sharedPositionMessage': 'My position from TrailPath',
      'sharePositionError': 'Could not share your position',
      'distanceToCar': 'Distance to car',
      'direction': 'Direction',
      'waitingForGps': 'Waiting for GPS',
      'gpsEvery': 'GPS update every',
    },
    'es': {
      'onboardingTitle': 'Antes de salir',
      'onboardingIntro': 'TrailPath te ayuda a planificar, registrar y seguir rutas outdoor incluso cuando no hay conexión.',
      'onboardingPlanTitle': 'Planifica por caminos y carreteras',
      'onboardingPlanBody': 'Toca el mapa, busca un lugar o dibuja el trazado. TrailPath ajusta la ruta a la red OSM cuando está disponible.',
      'onboardingOfflineTitle': 'Prepara un mapa offline',
      'onboardingOfflineBody': 'Descarga la zona de la ruta antes de salir para mantener disponible el mapa preparado y la navegación sin conexión.',
      'onboardingRecordTitle': 'Registra y navega',
      'onboardingRecordBody': 'Usa el GPS para registrar una actividad, seguir rutas guardadas y volver a la posición del coche.',
      'onboardingPrivacy': 'Las rutas y actividades permanecen en este dispositivo. TrailPath pide la ubicación solo cuando una función GPS la necesita.',
      'onboardingStart': 'Empezar con TrailPath',
      'planner': 'Planificar',
      'record': 'Registrar',
      'routes': 'Rutas',
      'searchPlace': 'Buscar lugar o sendero',
      'noSearchResults': 'No se encontraron resultados',
      'searchFailed': 'La búsqueda no está disponible. Inténtalo de nuevo',
      'createRoute': 'Crear una ruta',
      'pointPreview': 'Punto seleccionado',
      'startHere': 'Empezar aquí',
      'setDestination': 'Destino',
      'addWaypoint': 'Añadir parada',
      'chooseDestination': 'Elige destino',
      'chooseDestinationHint': 'Toca el mapa o busca un lugar',
      'routeDetails': 'Detalles de la ruta',
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
      'mapOutdoor': 'Outdoor',
      'mapStreet': 'Carreteras',
      'mapHighContrast': 'Alto contraste',
      'mapSatellite': 'Satélite',
      'mapHybrid': 'Satélite + carreteras',
      'proMap': 'Mapa Pro',
      'proMapUnavailable': 'Proveedor de mapas Pro no configurado',
      'trailPathPro': 'TrailPath Pro',
      'proSubtitle': 'Mapas y herramientas outdoor avanzadas',
      'proActive': 'TrailPath Pro activo',
      'proBenefitMaps': 'Satélite y mapas premium',
      'proBenefitTrace': 'Smart Trace y herramientas de ruta avanzadas',
      'proBenefitOffline': 'Funciones offline avanzadas',
      'proBenefitStats': 'Estadísticas y análisis avanzados',
      'proBenefitCloud': 'Sincronización cloud y copia entre dispositivos',
      'proMonthly': 'Mensual',
      'proYearly': 'Anual',
      'proMonthlyUnavailable': 'Plan mensual no configurado',
      'proYearlyUnavailable': 'Plan anual no configurado',
      'restorePurchases': 'Restaurar compras',
      'proStoreUnavailable': 'Google Play Billing no está disponible o los productos Pro aún no están configurados.',
      'proPurchaseError': 'No se pudo completar la compra.',
      'proSafetyFree': 'La grabación, recuperación y seguridad básicas siguen disponibles sin Pro.',
      'proRenewalNotice': 'La suscripción se renueva automáticamente por el periodo seleccionado hasta que se cancele en Google Play.',
      'profile': 'Perfil',
      'settings': 'Ajustes',
      'preferences': 'Preferencias de la app',
      'activitySummary': 'Resumen de actividad',
      'activities': 'Actividades',
      'totalDistance': 'Distancia total',
      'totalAscent': 'Desnivel total',
      'savedRoutesCount': 'Rutas guardadas',
      'outdoorTools': 'Herramientas Outdoor',
      'cloudSync': 'Cloud Sync',
      'cloudSyncAccountHint':
          'Copia y sincronización opcionales con una cuenta',
      'syncNow': 'Sincronizar ahora',
      'syncing': 'Sincronizando…',
      'syncLast': 'Última sincronización',
      'syncPending': 'cambios pendientes',
      'syncRequiresPro': 'Requiere TrailPath Pro',
      'syncRequiresAccount': 'Inicia sesión con Google para sincronizar',
      'syncUnavailable': 'Cloud Sync no está configurado en esta build',
      'syncReady': 'Listo para sincronizar',
      'syncDone': 'Sincronización completada',
      'syncError': 'Error de sincronización',
      'googleAccount': 'Cuenta de Google',
      'signInGoogle': 'Acceder',
      'signOut': 'Cerrar sesión',
      'accountOptional': 'La cuenta es opcional: TrailPath funciona offline y sin iniciar sesión.',
      'accountNotConfigured':
          'Google Sign-In no está configurado en esta build.',
      'appearance': 'Apariencia',
      'theme': 'Tema',
      'systemTheme': 'Sistema',
      'lightTheme': 'Claro',
      'darkTheme': 'Oscuro',
      'routePreferences': 'Preferencias de ruta',
      'defaultActivity': 'Actividad predeterminada',
      'defaultMap': 'Mapa predeterminado',
      'units': 'Unidades',
      'metricUnits': 'Métricas (km, m)',
      'imperialUnits': 'Imperiales (mi, ft)',
      'gpsAndDownloads': 'GPS y descargas',
      'voiceGuidance': 'Guía por voz',
      'voiceGuidanceHint': 'Usa avisos hablados durante la navegación.',
      'wifiOnlyDownloads': 'Mapas offline solo por Wi‑Fi',
      'wifiOnlyDownloadsHint':
          'No inicia nuevas descargas offline con datos móviles.',
      'privacyData': 'Privacidad y datos',
      'localFirst': 'Local-first',
      'localFirstHint': 'Las rutas y actividades quedan en el dispositivo salvo que actives expresamente la sincronización cloud.',
      'routeLab': 'Route Lab',
      'routeLabHint': 'Circuitos, alternativas, POI, tiempo y superficie',
      'circularRoute': 'Ruta circular',
      'circularRouteHint': 'Genera circuitos reales por carreteras y senderos OSM desde tu posición actual.',
      'generateRoutes': 'Generar rutas',
      'routeOption': 'Opción',
      'routeAlternatives': 'Rutas alternativas',
      'routeAlternativesUnavailable':
          'Las alternativas no están disponibles temporalmente',
      'shortestRoute': 'Más corta',
      'leastClimb': 'Menos subida',
      'moreTrail': 'Más sendero',
      'moreRoad': 'Más carretera',
      'generateAlternatives': 'Generar alternativas',
      'alternative': 'Alternativa',
      'routeContext': 'Contexto de ruta',
      'routeContextHint':
          'Analiza POI outdoor, tiempo y superficie en una ruta guardada.',
      'analyzeRoute': 'Analizar ruta',
      'surface': 'Superficie',
      'weatherAlongRoute': 'Tiempo a lo largo de la ruta',
      'outdoorPois': 'POI outdoor',
      'fromRoute': 'de la ruta',
      'noRouteCandidates':
          'No se encontró una ruta válida con estos parámetros.',
      'routeGenerationFailed': 'No se pudieron generar las rutas.',
      'routeContextFailed': 'No se pudo analizar el contexto de la ruta.',
      'surfacePaved': 'Pavimentado',
      'surfaceGravel': 'Grava/compactado',
      'surfaceDirt': 'Tierra',
      'surfaceTrail': 'Sendero/sin pavimentar',
      'surfaceUnknown': 'Desconocida',
      'routeCollections': 'Colecciones',
      'routeCollectionsHint': 'Organiza rutas en carpetas personales',
      'newCollection': 'Nueva colección',
      'collectionName': 'Nombre de la colección',
      'collectionsUnavailable':
          'Las colecciones no están disponibles temporalmente',
      'noCollections': 'Sin colecciones',
      'noCollectionsHint':
          'Crea carpetas para organizar rutas, viajes y actividades.',
      'manageCollection': 'Gestionar rutas',
      'deleteCollection': '¿Eliminar la colección?',
      'personalStats': 'Estadísticas',
      'personalStatsHint':
          'Analiza distancia, desnivel y actividad a lo largo del tiempo',
      'statsUnavailable': 'Las estadísticas no están disponibles temporalmente',
      'last7Days': 'Últimos 7 días',
      'last30Days': 'Últimos 30 días',
      'longestActivity': 'Actividad más larga',
      'highestAscent': 'Mayor desnivel',
      'movingTime': 'Tiempo en movimiento',
      'slopeMap': 'Mapa de pendiente',
      'slopeMapHint': 'Colorea la ruta según la pendiente',
      'terrain3d': 'Terreno 3D',
      'terrain3dHint': 'Relieve 3D basado en datos de elevación del mapa',
      'autoReroute': 'Recálculo automático',
      'autoRerouteHint':
          'Calcula una nueva ruta al destino al salir del trazado.',
      'autoRerouteProHint':
          'El recálculo automático está disponible con TrailPath Pro.',
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
      'routeDeleteFailed': 'No se pudo eliminar completamente la ruta',
      'routingReady': 'Routing listo',
      'routingCalculating': 'Calculando por caminos y carreteras…',
      'routeSnapped': 'Ruta ajustada a la red OSM',
      'routeUnavailable':
          'Routing no disponible: ajusta los puntos o inténtalo de nuevo',
      'routeNetworkUnavailable': 'Sin conexión: no se puede calcular la ruta',
      'routeTimeout': 'El cálculo está tardando demasiado: inténtalo de nuevo',
      'routeRateLimited': 'El servicio de rutas está ocupado: inténtalo en breve',
      'routeNoPath': 'No se encontró una ruta válida entre estos puntos',
      'routeProviderUnavailable': 'El servicio de rutas no está disponible temporalmente',
      'routeInvalidResponse': 'Respuesta de routing no válida: inténtalo de nuevo',
      'routeLocalFallback': 'Ruta local o GPX sin ajustar a la red',
      'routeEditHint': 'Toca la línea del recorrido para editarla; arrastra los puntos para moverlos.',
      'routeEditActive': 'Edición activa: arrastra los puntos blancos entre etapas para insertar nuevos.',
      'routeDragActive':
          'Arrastrando: suelta para recalcular solo el tramo modificado.',
      'traceMode': 'Dibujar ruta',
      'traceFollowTrails': 'Seguir senderos',
      'traceFollowRoads': 'Seguir carreteras',
      'traceFree': 'Libre',
      'traceCloseLoop': 'Cerrar circuito',
      'traceOutAndBack': 'Ida y vuelta',
      'traceReverse': 'Invertir',
      'traceErase': 'Borrar último tramo',
      'traceHint': 'Modo dibujo: arrastra el dedo por el mapa siguiendo el camino deseado.',
      'traceDrawing': 'Sigue dibujando; al soltar TrailPath ajustará el trazo a la red OSM.',
      'traceProcessing': 'Convirtiendo el gesto en una ruta real…',
      'traceTooShort': 'Dibuja un tramo un poco más largo.',
      'traceFailed': 'No se pudo convertir el gesto en una ruta.',
      'routePressTooFar': 'Mantén pulsado más cerca de la línea del recorrido.',
      'waypointSelected': 'Punto seleccionado',
      'removeWaypoint': 'Quitar',
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
      'activitySaveFailed':
          'No se pudo guardar la actividad. La ruta sigue siendo recuperable.',
      'retrySave': 'Reintentar guardado',
      'savePending': 'Guardado pendiente',
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
      'noOfflineMapsHint':
          'Abre Rutas y descarga el mapa de una ruta guardada.',
      'storageUsed': 'Espacio usado',
      'outdoor': 'Outdoor',
      'outdoorHint':
          'Herramientas rápidas para autonomía, regreso y seguridad en ruta.',
      'batteryMode': 'Modo de batería',
      'batteryPerformance': 'Rendimiento',
      'batteryBalanced': 'Equilibrado',
      'batterySaver': 'Ahorro',
      'batteryPerformanceHint':
          'GPS más frecuente y preciso para rutas y navegación exigentes.',
      'batteryBalancedHint':
          'Equilibra precisión GPS y autonomía para la mayoría de salidas.',
      'batterySaverHint':
          'Reduce las actualizaciones GPS para alargar la batería.',
      'backToCar': 'Back to Car',
      'backToCarHint':
          'Guarda el punto de aparcamiento y vuelve incluso sin conexión.',
      'saveCarHere': 'Guardar coche aquí',
      'updateCarPosition': 'Actualizar posición',
      'carPositionSaved': 'Posición del coche guardada',
      'carSavedAt': 'Guardado',
      'openBackToCar': 'Abrir Back to Car',
      'clearCar': 'Eliminar posición del coche',
      'clearCarHint': 'Se eliminará el punto guardado.',
      'safetyCheck': 'Safety Check',
      'safetyCheckHint':
          'Comprueba batería, GPS, permisos y mapas offline antes de salir.',
      'refresh': 'Actualizar',
      'battery': 'Batería',
      'systemBatterySaver': 'Ahorro del sistema',
      'gpsPermission': 'Permiso GPS',
      'locationServices': 'Servicios de ubicación',
      'offlineMap': 'Mapa offline',
      'sharePosition': 'Compartir posición',
      'sharePositionHint': 'Comparte tus coordenadas actuales con un contacto.',
      'sharedPositionMessage': 'Mi posición desde TrailPath',
      'sharePositionError': 'No se pudo compartir la posición',
      'distanceToCar': 'Distancia al coche',
      'direction': 'Dirección',
      'waitingForGps': 'Esperando GPS',
      'gpsEvery': 'Actualización GPS cada',
    },
    'fr': {
      'onboardingTitle': 'Avant de partir',
      'onboardingIntro': 'TrailPath vous aide à planifier, enregistrer et suivre des parcours outdoor, même sans connexion.',
      'onboardingPlanTitle': 'Planifiez sur chemins et routes',
      'onboardingPlanBody': 'Touchez la carte, recherchez un lieu ou dessinez la trace. TrailPath cale le parcours sur le réseau OSM lorsqu’il est disponible.',
      'onboardingOfflineTitle': 'Préparez une carte hors ligne',
      'onboardingOfflineBody': 'Téléchargez la zone du parcours avant de partir afin de garder la carte préparée et la navigation disponibles sans réseau.',
      'onboardingRecordTitle': 'Enregistrez et naviguez',
      'onboardingRecordBody': 'Utilisez le GPS pour enregistrer une activité, suivre des parcours sauvegardés et retrouver la position de la voiture.',
      'onboardingPrivacy': 'Les parcours et activités restent sur cet appareil. TrailPath demande la position uniquement lorsqu’une fonction GPS en a besoin.',
      'onboardingStart': 'Commencer avec TrailPath',
      'planner': 'Planifier',
      'record': 'Enregistrer',
      'routes': 'Parcours',
      'searchPlace': 'Rechercher un lieu ou sentier',
      'noSearchResults': 'Aucun résultat trouvé',
      'searchFailed': 'Recherche indisponible. Réessayez plus tard',
      'createRoute': 'Créer un parcours',
      'pointPreview': 'Point sélectionné',
      'startHere': 'Partir d’ici',
      'setDestination': 'Destination',
      'addWaypoint': 'Ajouter une étape',
      'chooseDestination': 'Choisissez la destination',
      'chooseDestinationHint': 'Touchez la carte ou recherchez un lieu',
      'routeDetails': 'Détails du parcours',
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
      'mapOutdoor': 'Outdoor',
      'mapStreet': 'Routes',
      'mapHighContrast': 'Contraste élevé',
      'mapSatellite': 'Satellite',
      'mapHybrid': 'Satellite + routes',
      'proMap': 'Carte Pro',
      'proMapUnavailable': 'Fournisseur de cartes Pro non configuré',
      'trailPathPro': 'TrailPath Pro',
      'proSubtitle': 'Cartes et outils outdoor avancés',
      'proActive': 'TrailPath Pro actif',
      'proBenefitMaps': 'Satellite et cartes premium',
      'proBenefitTrace': 'Smart Trace et outils de parcours avancés',
      'proBenefitOffline': 'Fonctions hors ligne avancées',
      'proBenefitStats': 'Statistiques et analyses avancées',
      'proBenefitCloud': 'Synchronisation cloud et sauvegarde multi-appareils',
      'proMonthly': 'Mensuel',
      'proYearly': 'Annuel',
      'proMonthlyUnavailable': 'Offre mensuelle non configurée',
      'proYearlyUnavailable': 'Offre annuelle non configurée',
      'restorePurchases': 'Restaurer les achats',
      'proStoreUnavailable': 'Google Play Billing est indisponible ou les produits Pro ne sont pas encore configurés.',
      'proPurchaseError': 'L’achat n’a pas pu être effectué.',
      'proSafetyFree': 'L’enregistrement, la récupération et les fonctions de sécurité essentielles restent disponibles sans Pro.',
      'proRenewalNotice': 'L’abonnement est renouvelé automatiquement pour la période choisie jusqu’à son annulation via Google Play.',
      'profile': 'Profil',
      'settings': 'Réglages',
      'preferences': 'Préférences de l’application',
      'activitySummary': 'Résumé d’activité',
      'activities': 'Activités',
      'totalDistance': 'Distance totale',
      'totalAscent': 'Dénivelé total',
      'savedRoutesCount': 'Parcours enregistrés',
      'outdoorTools': 'Outils Outdoor',
      'cloudSync': 'Cloud Sync',
      'cloudSyncAccountHint':
          'Sauvegarde et synchronisation facultatives avec un compte',
      'syncNow': 'Synchroniser',
      'syncing': 'Synchronisation…',
      'syncLast': 'Dernière synchronisation',
      'syncPending': 'modifications en attente',
      'syncRequiresPro': 'Nécessite TrailPath Pro',
      'syncRequiresAccount': 'Connectez-vous avec Google pour synchroniser',
      'syncUnavailable': 'Cloud Sync n’est pas configuré dans cette build',
      'syncReady': 'Prêt à synchroniser',
      'syncDone': 'Synchronisation terminée',
      'syncError': 'Erreur de synchronisation',
      'googleAccount': 'Compte Google',
      'signInGoogle': 'Se connecter',
      'signOut': 'Se déconnecter',
      'accountOptional': 'Le compte est facultatif : TrailPath fonctionne hors ligne et sans connexion.',
      'accountNotConfigured':
          'Google Sign-In n’est pas configuré dans cette build.',
      'appearance': 'Apparence',
      'theme': 'Thème',
      'systemTheme': 'Système',
      'lightTheme': 'Clair',
      'darkTheme': 'Sombre',
      'routePreferences': 'Préférences de parcours',
      'defaultActivity': 'Activité par défaut',
      'defaultMap': 'Carte par défaut',
      'units': 'Unités',
      'metricUnits': 'Métriques (km, m)',
      'imperialUnits': 'Impériales (mi, ft)',
      'gpsAndDownloads': 'GPS et téléchargements',
      'voiceGuidance': 'Guidage vocal',
      'voiceGuidanceHint':
          'Utiliser les annonces vocales pendant la navigation.',
      'wifiOnlyDownloads': 'Cartes hors ligne uniquement en Wi‑Fi',
      'wifiOnlyDownloadsHint': 'Ne pas démarrer de nouveau téléchargement hors ligne sur le réseau mobile.',
      'privacyData': 'Confidentialité et données',
      'localFirst': 'Local-first',
      'localFirstHint': 'Les parcours et activités restent sur l’appareil sauf activation explicite de la synchronisation cloud.',
      'routeLab': 'Route Lab',
      'routeLabHint': 'Boucles, alternatives, POI, météo et surface',
      'circularRoute': 'Parcours circulaire',
      'circularRouteHint': 'Générez des boucles réelles sur routes et sentiers OSM depuis votre position.',
      'generateRoutes': 'Générer des parcours',
      'routeOption': 'Option',
      'routeAlternatives': 'Parcours alternatifs',
      'routeAlternativesUnavailable':
          'Les alternatives sont temporairement indisponibles',
      'shortestRoute': 'Plus court',
      'leastClimb': 'Moins de montée',
      'moreTrail': 'Plus de sentiers',
      'moreRoad': 'Plus de route',
      'generateAlternatives': 'Générer des alternatives',
      'alternative': 'Alternative',
      'routeContext': 'Contexte du parcours',
      'routeContextHint': 'Analysez les POI outdoor, la météo et la surface d’un parcours enregistré.',
      'analyzeRoute': 'Analyser le parcours',
      'surface': 'Surface',
      'weatherAlongRoute': 'Météo le long du parcours',
      'outdoorPois': 'POI outdoor',
      'fromRoute': 'du parcours',
      'noRouteCandidates': 'Aucun parcours valide trouvé pour ces paramètres.',
      'routeGenerationFailed': 'Impossible de générer les parcours.',
      'routeContextFailed': 'Impossible d’analyser le contexte du parcours.',
      'surfacePaved': 'Revêtu',
      'surfaceGravel': 'Gravier/compacté',
      'surfaceDirt': 'Terre',
      'surfaceTrail': 'Sentier/non revêtu',
      'surfaceUnknown': 'Inconnue',
      'routeCollections': 'Collections',
      'routeCollectionsHint':
          'Organisez les parcours dans des dossiers personnels',
      'newCollection': 'Nouvelle collection',
      'collectionName': 'Nom de la collection',
      'collectionsUnavailable': 'Collections temporairement indisponibles',
      'noCollections': 'Aucune collection',
      'noCollectionsHint':
          'Créez des dossiers pour organiser parcours, voyages et activités.',
      'manageCollection': 'Gérer les parcours',
      'deleteCollection': 'Supprimer la collection ?',
      'personalStats': 'Statistiques',
      'personalStatsHint':
          'Analysez distance, dénivelé et activité dans le temps',
      'statsUnavailable': 'Statistiques temporairement indisponibles',
      'last7Days': '7 derniers jours',
      'last30Days': '30 derniers jours',
      'longestActivity': 'Activité la plus longue',
      'highestAscent': 'Dénivelé maximal',
      'movingTime': 'Temps en mouvement',
      'slopeMap': 'Carte des pentes',
      'slopeMapHint': 'Colore le parcours selon la pente',
      'terrain3d': 'Terrain 3D',
      'terrain3dHint': 'Relief 3D basé sur les données d’altitude de la carte',
      'autoReroute': 'Recalcul automatique',
      'autoRerouteHint': 'Calcule un nouveau parcours vers la destination en quittant la trace.',
      'autoRerouteProHint':
          'Le recalcul automatique est disponible avec TrailPath Pro.',
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
      'routeDeleteFailed': 'Impossible de supprimer complètement le parcours',
      'routingReady': 'Routage prêt',
      'routingCalculating': 'Calcul sur chemins et routes…',
      'routeSnapped': 'Parcours calé sur le réseau OSM',
      'routeUnavailable':
          'Itinéraire indisponible : modifiez les points ou réessayez',
      'routeNetworkUnavailable': 'Pas de connexion : impossible de calculer le parcours',
      'routeTimeout': 'Le calcul prend trop de temps : réessayez',
      'routeRateLimited': 'Le service de routage est temporairement occupé',
      'routeNoPath': 'Aucun parcours valide trouvé entre ces points',
      'routeProviderUnavailable': 'Service de routage temporairement indisponible',
      'routeInvalidResponse': 'Réponse de routage invalide : réessayez',
      'routeLocalFallback': 'Itinéraire local ou GPX non accroché au réseau',
      'routeEditHint': 'Touchez la ligne du parcours pour la modifier ; faites glisser les points pour les déplacer.',
      'routeEditActive': 'Modification active : faites glisser les points blancs entre les étapes pour en insérer.',
      'routeDragActive': 'Déplacement en cours : relâchez pour recalculer uniquement le tronçon modifié.',
      'traceMode': 'Dessiner l’itinéraire',
      'traceFollowTrails': 'Suivre les sentiers',
      'traceFollowRoads': 'Suivre les routes',
      'traceFree': 'Libre',
      'traceCloseLoop': 'Fermer la boucle',
      'traceOutAndBack': 'Aller-retour',
      'traceReverse': 'Inverser',
      'traceErase': 'Effacer le dernier tronçon',
      'traceHint': 'Mode dessin : faites glisser votre doigt sur la carte le long du chemin souhaité.',
      'traceDrawing': 'Continuez à dessiner ; au relâchement TrailPath accrochera le tracé au réseau OSM.',
      'traceProcessing': 'Conversion du geste en itinéraire réel…',
      'traceTooShort': 'Dessinez un tronçon un peu plus long.',
      'traceFailed': 'Impossible de convertir le geste en itinéraire.',
      'routePressTooFar':
          'Effectuez un appui long plus près de la ligne du parcours.',
      'waypointSelected': 'Point sélectionné',
      'removeWaypoint': 'Retirer',
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
      'activitySaveFailed': 'Échec de l’enregistrement de l’activité. La trace reste récupérable.',
      'retrySave': 'Réessayer l’enregistrement',
      'savePending': 'Enregistrement en attente',
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
      'backToRouteHint':
          'Revenez vers la ligne du parcours affichée sur la carte.',
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
      'noOfflineMapsHint':
          'Ouvrez Parcours et téléchargez la carte d’un parcours enregistré.',
      'storageUsed': 'Espace utilisé',
      'outdoor': 'Outdoor',
      'outdoorHint':
          'Outils rapides pour autonomie, retour et sécurité sur le terrain.',
      'batteryMode': 'Mode batterie',
      'batteryPerformance': 'Performance',
      'batteryBalanced': 'Équilibré',
      'batterySaver': 'Économie',
      'batteryPerformanceHint':
          'GPS plus fréquent et précis pour les parcours exigeants.',
      'batteryBalancedHint':
          'Équilibre précision GPS et autonomie pour la plupart des sorties.',
      'batterySaverHint':
          'Réduit les mises à jour GPS pour prolonger l’autonomie.',
      'backToCar': 'Back to Car',
      'backToCarHint':
          'Enregistrez votre parking et retrouvez-le même sans réseau.',
      'saveCarHere': 'Enregistrer la voiture ici',
      'updateCarPosition': 'Mettre à jour',
      'carPositionSaved': 'Position de la voiture enregistrée',
      'carSavedAt': 'Enregistrée',
      'openBackToCar': 'Ouvrir Back to Car',
      'clearCar': 'Supprimer la position voiture',
      'clearCarHint': 'Le point enregistré sera supprimé.',
      'safetyCheck': 'Safety Check',
      'safetyCheckHint': 'Vérifiez batterie, GPS, autorisations et cartes hors ligne avant de partir.',
      'refresh': 'Actualiser',
      'battery': 'Batterie',
      'systemBatterySaver': 'Économie système',
      'gpsPermission': 'Autorisation GPS',
      'locationServices': 'Services de localisation',
      'offlineMap': 'Carte hors ligne',
      'sharePosition': 'Partager la position',
      'sharePositionHint':
          'Partagez vos coordonnées actuelles avec un contact.',
      'sharedPositionMessage': 'Ma position depuis TrailPath',
      'sharePositionError': 'Impossible de partager la position',
      'distanceToCar': 'Distance à la voiture',
      'direction': 'Direction',
      'waitingForGps': 'En attente du GPS',
      'gpsEvery': 'Mise à jour GPS toutes les',
    },
    'pt': {
      'onboardingTitle': 'Antes de sair',
      'onboardingIntro': 'O TrailPath ajuda a planear, gravar e seguir percursos outdoor, mesmo quando não há ligação à rede.',
      'onboardingPlanTitle': 'Planeie em trilhos e estradas',
      'onboardingPlanBody': 'Toque no mapa, procure um local ou desenhe o traçado. O TrailPath ajusta o percurso à rede OSM quando disponível.',
      'onboardingOfflineTitle': 'Prepare um mapa offline',
      'onboardingOfflineBody': 'Descarregue a zona do percurso antes de sair para manter o mapa preparado e a navegação disponíveis sem rede.',
      'onboardingRecordTitle': 'Grave e navegue',
      'onboardingRecordBody': 'Use o GPS para gravar uma atividade, seguir percursos guardados e voltar à posição do carro.',
      'onboardingPrivacy': 'Os percursos e atividades ficam neste dispositivo. O TrailPath pede a localização apenas quando uma função GPS precisa dela.',
      'onboardingStart': 'Começar com TrailPath',
      'planner': 'Planear',
      'record': 'Gravar',
      'routes': 'Percursos',
      'searchPlace': 'Pesquisar local ou trilho',
      'noSearchResults': 'Nenhum resultado encontrado',
      'searchFailed': 'Pesquisa indisponível. Tente novamente mais tarde',
      'createRoute': 'Criar um percurso',
      'pointPreview': 'Ponto selecionado',
      'startHere': 'Começar aqui',
      'setDestination': 'Destino',
      'addWaypoint': 'Adicionar etapa',
      'chooseDestination': 'Escolha o destino',
      'chooseDestinationHint': 'Toque no mapa ou pesquise um local',
      'routeDetails': 'Detalhes do percurso',
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
      'mapOutdoor': 'Outdoor',
      'mapStreet': 'Estradas',
      'mapHighContrast': 'Alto contraste',
      'mapSatellite': 'Satélite',
      'mapHybrid': 'Satélite + estradas',
      'proMap': 'Mapa Pro',
      'proMapUnavailable': 'Fornecedor de mapas Pro não configurado',
      'trailPathPro': 'TrailPath Pro',
      'proSubtitle': 'Mapas e ferramentas outdoor avançadas',
      'proActive': 'TrailPath Pro ativo',
      'proBenefitMaps': 'Satélite e mapas premium',
      'proBenefitTrace': 'Smart Trace e ferramentas de rota avançadas',
      'proBenefitOffline': 'Funcionalidades offline avançadas',
      'proBenefitStats': 'Estatísticas e análises avançadas',
      'proBenefitCloud': 'Sincronização cloud e backup entre dispositivos',
      'proMonthly': 'Mensal',
      'proYearly': 'Anual',
      'proMonthlyUnavailable': 'Plano mensal não configurado',
      'proYearlyUnavailable': 'Plano anual não configurado',
      'restorePurchases': 'Restaurar compras',
      'proStoreUnavailable': 'Google Play Billing não está disponível ou os produtos Pro ainda não estão configurados.',
      'proPurchaseError': 'Não foi possível concluir a compra.',
      'proSafetyFree': 'Gravação, recuperação e funcionalidades essenciais de segurança continuam disponíveis sem Pro.',
      'proRenewalNotice': 'A subscrição renova-se automaticamente pelo período selecionado até ser cancelada no Google Play.',
      'profile': 'Perfil',
      'settings': 'Definições',
      'preferences': 'Preferências da app',
      'activitySummary': 'Resumo de atividade',
      'activities': 'Atividades',
      'totalDistance': 'Distância total',
      'totalAscent': 'Desnível total',
      'savedRoutesCount': 'Percursos guardados',
      'outdoorTools': 'Ferramentas Outdoor',
      'cloudSync': 'Cloud Sync',
      'cloudSyncAccountHint': 'Backup e sincronização opcionais com uma conta',
      'syncNow': 'Sincronizar agora',
      'syncing': 'A sincronizar…',
      'syncLast': 'Última sincronização',
      'syncPending': 'alterações pendentes',
      'syncRequiresPro': 'Requer TrailPath Pro',
      'syncRequiresAccount': 'Entre com Google para sincronizar',
      'syncUnavailable': 'Cloud Sync não está configurado nesta build',
      'syncReady': 'Pronto para sincronizar',
      'syncDone': 'Sincronização concluída',
      'syncError': 'Erro de sincronização',
      'googleAccount': 'Conta Google',
      'signInGoogle': 'Entrar',
      'signOut': 'Terminar sessão',
      'accountOptional':
          'A conta é opcional: o TrailPath funciona offline e sem login.',
      'accountNotConfigured':
          'Google Sign-In não está configurado nesta build.',
      'appearance': 'Aparência',
      'theme': 'Tema',
      'systemTheme': 'Sistema',
      'lightTheme': 'Claro',
      'darkTheme': 'Escuro',
      'routePreferences': 'Preferências de rota',
      'defaultActivity': 'Atividade predefinida',
      'defaultMap': 'Mapa predefinido',
      'units': 'Unidades',
      'metricUnits': 'Métricas (km, m)',
      'imperialUnits': 'Imperiais (mi, ft)',
      'gpsAndDownloads': 'GPS e downloads',
      'voiceGuidance': 'Orientação por voz',
      'voiceGuidanceHint': 'Usa avisos falados durante a navegação.',
      'wifiOnlyDownloads': 'Mapas offline apenas por Wi‑Fi',
      'wifiOnlyDownloadsHint':
          'Não inicia novos downloads offline em dados móveis.',
      'privacyData': 'Privacidade e dados',
      'localFirst': 'Local-first',
      'localFirstHint': 'Percursos e atividades ficam no dispositivo salvo sincronização cloud explicitamente ativada.',
      'routeLab': 'Route Lab',
      'routeLabHint': 'Circuitos, alternativas, POI, meteorologia e superfície',
      'circularRoute': 'Percurso circular',
      'circularRouteHint': 'Gera circuitos reais em estradas e trilhos OSM a partir da posição atual.',
      'generateRoutes': 'Gerar percursos',
      'routeOption': 'Opção',
      'routeAlternatives': 'Percursos alternativos',
      'routeAlternativesUnavailable':
          'As alternativas estão temporariamente indisponíveis',
      'shortestRoute': 'Mais curto',
      'leastClimb': 'Menos subida',
      'moreTrail': 'Mais trilho',
      'moreRoad': 'Mais estrada',
      'generateAlternatives': 'Gerar alternativas',
      'alternative': 'Alternativa',
      'routeContext': 'Contexto do percurso',
      'routeContextHint': 'Analisa POI outdoor, meteorologia e superfície num percurso guardado.',
      'analyzeRoute': 'Analisar percurso',
      'surface': 'Superfície',
      'weatherAlongRoute': 'Meteorologia ao longo do percurso',
      'outdoorPois': 'POI outdoor',
      'fromRoute': 'do percurso',
      'noRouteCandidates':
          'Nenhum percurso válido encontrado para estes parâmetros.',
      'routeGenerationFailed': 'Não foi possível gerar os percursos.',
      'routeContextFailed': 'Não foi possível analisar o contexto do percurso.',
      'surfacePaved': 'Pavimentado',
      'surfaceGravel': 'Cascalho/compactado',
      'surfaceDirt': 'Terra',
      'surfaceTrail': 'Trilho/não pavimentado',
      'surfaceUnknown': 'Desconhecida',
      'routeCollections': 'Coleções',
      'routeCollectionsHint': 'Organiza percursos em pastas pessoais',
      'newCollection': 'Nova coleção',
      'collectionName': 'Nome da coleção',
      'collectionsUnavailable': 'Coleções temporariamente indisponíveis',
      'noCollections': 'Sem coleções',
      'noCollectionsHint':
          'Cria pastas para organizar percursos, viagens e atividades.',
      'manageCollection': 'Gerir percursos',
      'deleteCollection': 'Eliminar coleção?',
      'personalStats': 'Estatísticas',
      'personalStatsHint':
          'Analisa distância, desnível e atividade ao longo do tempo',
      'statsUnavailable': 'Estatísticas temporariamente indisponíveis',
      'last7Days': 'Últimos 7 dias',
      'last30Days': 'Últimos 30 dias',
      'longestActivity': 'Atividade mais longa',
      'highestAscent': 'Maior desnível',
      'movingTime': 'Tempo em movimento',
      'slopeMap': 'Mapa de inclinação',
      'slopeMapHint': 'Colore o percurso conforme a inclinação',
      'terrain3d': 'Terreno 3D',
      'terrain3dHint': 'Relevo 3D baseado nos dados de elevação do mapa',
      'autoReroute': 'Recálculo automático',
      'autoRerouteHint':
          'Calcula um novo percurso até ao destino quando sai da rota.',
      'autoRerouteProHint':
          'O recálculo automático está disponível com TrailPath Pro.',
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
      'routeDeleteFailed': 'Não foi possível eliminar completamente o percurso',
      'routingReady': 'Roteamento pronto',
      'routingCalculating': 'A calcular por trilhos e estradas…',
      'routeSnapped': 'Percurso ajustado à rede OSM',
      'routeUnavailable':
          'Roteamento indisponível: ajuste os pontos ou tente novamente',
      'routeNetworkUnavailable': 'Sem ligação: não é possível calcular a rota',
      'routeTimeout': 'O cálculo está a demorar demasiado: tente novamente',
      'routeRateLimited': 'O serviço de rotas está ocupado: tente novamente em breve',
      'routeNoPath': 'Não foi encontrada uma rota válida entre estes pontos',
      'routeProviderUnavailable': 'Serviço de rotas temporariamente indisponível',
      'routeInvalidResponse': 'Resposta de roteamento inválida: tente novamente',
      'routeLocalFallback': 'Rota local ou GPX não ajustada à rede',
      'routeEditHint': 'Toque na linha do percurso para editar; arraste os pontos para os mover.',
      'routeEditActive': 'Edição ativa: arraste os pontos brancos entre etapas para inserir novos.',
      'routeDragActive':
          'A arrastar: solte para recalcular apenas o troço alterado.',
      'traceMode': 'Desenhar rota',
      'traceFollowTrails': 'Seguir trilhos',
      'traceFollowRoads': 'Seguir estradas',
      'traceFree': 'Livre',
      'traceCloseLoop': 'Fechar circuito',
      'traceOutAndBack': 'Ida e volta',
      'traceReverse': 'Inverter',
      'traceErase': 'Apagar último troço',
      'traceHint': 'Modo desenho: arraste o dedo pelo mapa seguindo o caminho pretendido.',
      'traceDrawing': 'Continue a desenhar; ao soltar, o TrailPath ajustará o traço à rede OSM.',
      'traceProcessing': 'A converter o gesto numa rota real…',
      'traceTooShort': 'Desenhe um troço um pouco mais longo.',
      'traceFailed': 'Não foi possível converter o gesto numa rota.',
      'routePressTooFar': 'Mantenha premido mais perto da linha do percurso.',
      'waypointSelected': 'Ponto selecionado',
      'removeWaypoint': 'Remover',
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
      'activitySaveFailed':
          'Falha ao guardar a atividade. O percurso continua recuperável.',
      'retrySave': 'Tentar guardar novamente',
      'savePending': 'Guardado pendente',
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
      'noOfflineMapsHint':
          'Abra Percursos e descarregue o mapa de um percurso guardado.',
      'storageUsed': 'Espaço usado',
      'outdoor': 'Outdoor',
      'outdoorHint': 'Ferramentas rápidas para autonomia, regresso e segurança no percurso.',
      'batteryMode': 'Modo de bateria',
      'batteryPerformance': 'Desempenho',
      'batteryBalanced': 'Equilibrado',
      'batterySaver': 'Poupança',
      'batteryPerformanceHint':
          'GPS mais frequente e preciso para percursos exigentes.',
      'batteryBalancedHint':
          'Equilibra precisão GPS e autonomia para a maioria das saídas.',
      'batterySaverHint': 'Reduz as atualizações GPS para prolongar a bateria.',
      'backToCar': 'Back to Car',
      'backToCarHint':
          'Guarde o local do estacionamento e volte mesmo sem rede.',
      'saveCarHere': 'Guardar carro aqui',
      'updateCarPosition': 'Atualizar posição',
      'carPositionSaved': 'Posição do carro guardada',
      'carSavedAt': 'Guardada',
      'openBackToCar': 'Abrir Back to Car',
      'clearCar': 'Remover posição do carro',
      'clearCarHint': 'O ponto guardado será eliminado.',
      'safetyCheck': 'Safety Check',
      'safetyCheckHint':
          'Verifique bateria, GPS, permissões e mapas offline antes de sair.',
      'refresh': 'Atualizar',
      'battery': 'Bateria',
      'systemBatterySaver': 'Poupança do sistema',
      'gpsPermission': 'Permissão GPS',
      'locationServices': 'Serviços de localização',
      'offlineMap': 'Mapa offline',
      'sharePosition': 'Partilhar posição',
      'sharePositionHint': 'Partilhe as coordenadas atuais com um contacto.',
      'sharedPositionMessage': 'A minha posição no TrailPath',
      'sharePositionError': 'Não foi possível partilhar a posição',
      'distanceToCar': 'Distância ao carro',
      'direction': 'Direção',
      'waitingForGps': 'A aguardar GPS',
      'gpsEvery': 'Atualização GPS a cada',
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
