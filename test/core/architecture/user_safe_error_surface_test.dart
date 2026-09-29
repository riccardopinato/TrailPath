import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary user surfaces do not render raw technical errors', () {
    final files = <String>[
      'lib/features/settings/presentation/settings_screen.dart',
      'lib/features/navigation/presentation/navigation_screen.dart',
      'lib/features/offline/presentation/offline_screen.dart',
      'lib/features/routes/presentation/routes_screen.dart',
      'lib/features/recording/presentation/record_screen.dart',
      'lib/features/outdoor/presentation/outdoor_screen.dart',
      'lib/features/outdoor/presentation/back_to_car_screen.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains('Text(error.toString())')),
        reason: '$path must not render raw exception text.',
      );
      expect(
        source,
        isNot(contains('message: error.toString()')),
        reason: '$path must not render raw exception messages.',
      );
      expect(
        source,
        isNot(contains('snapshot.error.toString()')),
        reason: '$path must not render raw Future errors.',
      );
      expect(
        source,
        isNot(contains('state.error!')),
        reason: '$path must not render raw controller errors.',
      );
    }
  });
}
