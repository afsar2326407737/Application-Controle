import 'dart:typed_data';

class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.displayName,
    this.iconBytes,
  });

  final String packageName;
  final String displayName;
  final Uint8List? iconBytes;

  factory AppInfo.fromMap(Map<Object?, Object?> map) {
    return AppInfo(
      packageName: map['packageName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unknown app',
      iconBytes: map['icon'] is Uint8List
          ? map['icon'] as Uint8List
          : map['icon'] is List<int>
          ? Uint8List.fromList(map['icon'] as List<int>)
          : null,
    );
  }

  Map<String, Object?> toMap() => {
    'packageName': packageName,
    'displayName': displayName,
    'iconBytes': iconBytes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          other.packageName == packageName &&
          other.displayName == displayName;

  @override
  int get hashCode => Object.hash(packageName, displayName);
}
