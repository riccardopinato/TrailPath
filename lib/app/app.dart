import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trail_path/app/theme/app_theme.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/home/presentation/home_shell.dart';

class TrailPathApp extends StatelessWidget {
  const TrailPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailPath',
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
