import 'package:flutter/material.dart';

import '../../data/models/app_info.dart';
import 'app_icon.dart';

class AppSelectionList extends StatelessWidget {
  const AppSelectionList({
    required this.apps,
    required this.selectedPackages,
    required this.onToggle,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final List<AppInfo> apps;
  final Set<String> selectedPackages;
  final ValueChanged<AppInfo> onToggle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final app = apps[index];
        final selected = selectedPackages.contains(app.packageName);
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => onToggle(app),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 66),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  AppIcon(app: app, size: 44),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      app.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onToggle(app),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
