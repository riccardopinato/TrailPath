import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/core/localization/measurement_formatter.dart';

class RouteCollectionsScreen extends ConsumerWidget {
  const RouteCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final collections = ref.watch(routeCollectionsProvider);
    final routes = ref.watch(savedRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.routeCollections),
        actions: [
          IconButton(
            tooltip: strings.newCollection,
            onPressed: () => _createCollection(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: collections.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stackTrace) =>
            Center(child: Text(strings.collectionsUnavailable)),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_copy_outlined, size: 58),
                    const SizedBox(height: 14),
                    Text(
                      strings.noCollections,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.noCollectionsHint,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _createCollection(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(strings.newCollection),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final collection = items[index];
              return FutureBuilder<List<String>>(
                future: ref
                    .read(appDatabaseProvider)
                    .listCollectionRouteIds(collection.id),
                builder: (context, snapshot) {
                  final routeIds = snapshot.data ?? const <String>[];
                  final routeNames =
                      routes.asData?.value
                          .where((route) => routeIds.contains(route.id))
                          .map((route) => route.name)
                          .toList(growable: false) ??
                      const <String>[];
                  return _CollectionCard(
                    collection: collection,
                    count: routeIds.length,
                    routeNames: routeNames,
                    onManage: () => _manageCollection(context, ref, collection),
                    onDelete: () => _deleteCollection(context, ref, collection),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.newCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.collectionName),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    await ref.read(appDatabaseProvider).createRouteCollection(name);
  }

  Future<void> _manageCollection(
    BuildContext context,
    WidgetRef ref,
    RouteCollection collection,
  ) async {
    final strings = AppLocalizations.of(context);
    final database = ref.read(appDatabaseProvider);
    final routes = await database.listSavedRoutes();
    final selected = (await database.listCollectionRouteIds(collection.id))
        .toSet();
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      collection.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Expanded(
                  child: routes.isEmpty
                      ? Center(child: Text(strings.noRoutes))
                      : ListView.builder(
                          itemCount: routes.length,
                          itemBuilder: (context, index) {
                            final route = routes[index];
                            return CheckboxListTile(
                              value: selected.contains(route.id),
                              title: Text(route.name),
                              subtitle: Text(context.formatDistance(route.distanceMeters)),
                              onChanged: (value) async {
                                if (value == true) {
                                  await database.addRouteToCollection(
                                    collection.id,
                                    route.id,
                                  );
                                  selected.add(route.id);
                                } else {
                                  await database.removeRouteFromCollection(
                                    collection.id,
                                    route.id,
                                  );
                                  selected.remove(route.id);
                                }
                                if (context.mounted) {
                                  setModalState(() {});
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCollection(
    BuildContext context,
    WidgetRef ref,
    RouteCollection collection,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteCollection),
        content: Text(collection.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appDatabaseProvider).deleteRouteCollection(collection.id);
    }
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.count,
    required this.routeNames,
    required this.onManage,
    required this.onDelete,
  });

  final RouteCollection collection;
  final int count;
  final List<String> routeNames;
  final VoidCallback onManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: const Icon(Icons.folder_rounded),
        title: Text(
          collection.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          routeNames.isEmpty
              ? '$count ${strings.routes}'
              : routeNames.take(3).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onManage,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'manage') {
              onManage();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'manage',
              child: Text(strings.manageCollection),
            ),
            PopupMenuItem(value: 'delete', child: Text(strings.delete)),
          ],
        ),
      ),
    );
  }
}

