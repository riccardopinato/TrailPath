import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/infrastructure/recording/foreground_notification_copy.dart';

void main() {
  test('foreground recording notification supports every app language', () {
    final copies = <String, ForegroundNotificationCopy>{
      for (final language in const ['it', 'en', 'es', 'fr', 'pt'])
        language: foregroundNotificationCopyForLanguage(language),
    };

    for (final copy in copies.values) {
      expect(copy.title, contains('TrailPath'));
      expect(copy.title.trim(), isNotEmpty);
      expect(copy.text.trim(), isNotEmpty);
    }

    expect(copies['it']!.title, contains('registrazione'));
    expect(copies['en']!.title, contains('recording'));
    expect(copies['es']!.title, contains('grabación'));
    expect(copies['fr']!.title, contains('enregistrement'));
    expect(copies['pt']!.title, contains('gravação'));
  });

  test('foreground recording notification falls back to English', () {
    final copy = foregroundNotificationCopyForLanguage('de');

    expect(copy.title, 'TrailPath · recording active');
    expect(
      copy.text,
      'GPS tracking continues while TrailPath is in the background.',
    );
  });
}
