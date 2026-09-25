import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final savedRoutesProvider = StreamProvider<List<SavedRoute>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchSavedRoutes();
});

final completedActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchCompletedActivities();
});

final returnPointProvider = StreamProvider<ReturnPoint?>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchReturnPoint();
});
