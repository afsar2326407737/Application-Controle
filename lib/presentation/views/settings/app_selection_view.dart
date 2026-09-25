import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_info.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/app_selection_list.dart';

class AppSelectionView extends StatefulWidget {
  const AppSelectionView({super.key});

  @override
  State<AppSelectionView> createState() => _AppSelectionViewState();
}

class _AppSelectionViewState extends State<AppSelectionView> {
  final _searchController = TextEditingController();
  late Set<String> _selected;
  late Map<String, String> _names;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppViewModel>().settings;
    _selected = settings.selectedPackages.toSet();
    _names = Map<String, String>.from(settings.selectedAppNames);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsViewModel>().loadApps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final query = _searchController.text.trim().toLowerCase();
    final apps = query.isEmpty
        ? viewModel.availableApps
        : viewModel.availableApps
              .where(
                (app) =>
                    app.displayName.toLowerCase().contains(query) ||
                    app.packageName.toLowerCase().contains(query),
              )
              .toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Apps to notice')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search apps',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selected.length} selected',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  'Stored only on this device',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: viewModel.isLoadingApps
                ? const Center(child: CircularProgressIndicator())
                : apps.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        query.isEmpty
                            ? 'No launchable apps were found.'
                            : 'No apps match “${_searchController.text}”.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : AppSelectionList(
                    apps: apps,
                    selectedPackages: _selected,
                    onToggle: _toggle,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.setSelectedApps(_selected, _names);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text('Save ${_selected.length} selected'),
          ),
        ),
      ),
    );
  }

  void _toggle(AppInfo app) {
    setState(() {
      if (!_selected.remove(app.packageName)) {
        _selected.add(app.packageName);
        _names[app.packageName] = app.displayName;
      } else {
        _names.remove(app.packageName);
      }
    });
  }
}
