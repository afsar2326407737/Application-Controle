abstract final class AppConstants {
  static const appName = 'Unloop';
  static const appTagline = 'A little more room for what matters.';
  static const databaseName = 'unloop.db';
  static const databaseVersion = 2;

  static const channelId = 'com.unloop.app/native';
  static const blockerEnabledKey = 'blocker_enabled';
  static const blockerPackagesKey = 'blocker_packages';
  static const pendingBlockerPackageKey = 'pending_blocker_package';
  static const pendingBlockerNameKey = 'pending_blocker_name';

  static const focusDurations = <int>[15, 25, 45, 60];
  static const reminderTask = 'unloopDailyReminder';
  static const reminderWorkName = 'unloop-daily-reminder';
}

/// Android supports no runtime dialog for Usage Access, so it is opened in
/// Settings. The strings are kept together to keep onboarding copy consistent.
abstract final class PermissionCopy {
  static const usageTitle = 'See the full picture';
  static const usageBody =
      'Usage access lets Unloop read app names and time spent. It never reads '
      'posts, messages, photos, or notification content.';
  static const notificationTitle = 'Gentle reminders';
  static const notificationBody =
      'Notifications let Unloop mark a focus session complete or offer your '
      'chosen daily reflection.';
  static const blockerTitle = 'Optional app redirect';
  static const blockerBody =
      'Accessibility access can return you to Unloop when a selected app opens. '
      'Unloop cannot see screen content and always includes an in-app stop.';
}
