abstract final class Formatters {
  static String duration(Duration value, {bool compact = false}) {
    final totalSeconds = value.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final paddedSeconds = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return compact
          ? '${hours}h ${minutes}m'
          : '${hours.toString().padLeft(2, '0')}:'
                '${minutes.toString().padLeft(2, '0')}:'
                '$paddedSeconds';
    }
    return compact
        ? '${minutes}m'
        : '${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }

  static String minutes(int value) {
    if (value < 60) return '${value}m';
    final hours = value ~/ 60;
    final minutes = value % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  static String percent(double value) => '${(value * 100).round()}%';
}
