class ForegroundNotificationCopy {
  const ForegroundNotificationCopy({required this.title, required this.text});

  final String title;
  final String text;
}

ForegroundNotificationCopy foregroundNotificationCopyForLanguage(
  String? languageCode,
) {
  return switch (languageCode?.toLowerCase()) {
    'it' => const ForegroundNotificationCopy(
      title: 'TrailPath · registrazione attiva',
      text: 'La traccia GPS continua anche con TrailPath in background.',
    ),
    'es' => const ForegroundNotificationCopy(
      title: 'TrailPath · grabación activa',
      text: 'La ruta GPS continúa aunque TrailPath esté en segundo plano.',
    ),
    'fr' => const ForegroundNotificationCopy(
      title: 'TrailPath · enregistrement actif',
      text: 'Le suivi GPS continue lorsque TrailPath est en arrière-plan.',
    ),
    'pt' => const ForegroundNotificationCopy(
      title: 'TrailPath · gravação ativa',
      text: 'O registo GPS continua mesmo com o TrailPath em segundo plano.',
    ),
    _ => const ForegroundNotificationCopy(
      title: 'TrailPath · recording active',
      text: 'GPS tracking continues while TrailPath is in the background.',
    ),
  };
}
