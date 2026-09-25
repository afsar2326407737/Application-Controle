class BlockedApp {
  const BlockedApp({
    required this.packageName,
    required this.displayName,
    this.selected = true,
    this.blockedUntil,
  });

  final String packageName;
  final String displayName;
  final bool selected;
  final DateTime? blockedUntil;

  BlockedApp copyWith({
    String? displayName,
    bool? selected,
    DateTime? blockedUntil,
    bool clearBlockedUntil = false,
  }) {
    return BlockedApp(
      packageName: packageName,
      displayName: displayName ?? this.displayName,
      selected: selected ?? this.selected,
      blockedUntil: clearBlockedUntil
          ? null
          : blockedUntil ?? this.blockedUntil,
    );
  }

  Map<String, Object?> toMap() => {
    'package_name': packageName,
    'display_name': displayName,
    'selected': selected ? 1 : 0,
    'blocked_until': blockedUntil?.millisecondsSinceEpoch,
  };

  factory BlockedApp.fromMap(Map<String, Object?> map) {
    return BlockedApp(
      packageName: map['package_name'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Unknown app',
      selected: (map['selected'] as int? ?? 1) == 1,
      blockedUntil: map['blocked_until'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['blocked_until'] as int),
    );
  }
}
