import 'package:kaminari/src/data/services/local_storage_service.dart';

class StatsService {
  static final LocalStorageService _storage = LocalStorageService();

  static int getDailyStreak() {
    final lastActiveStr = _storage.getData('last_active_date') as String?;
    final streak = _storage.getData('current_streak') as int? ?? 0;

    if (lastActiveStr == null) return 0;

    final lastActive = DateTime.parse(lastActiveStr);
    final now = DateTime.now();

    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastActive.year, lastActive.month, lastActive.day))
        .inDays;

    if (difference <= 1) {
      // 0 means already recorded today, 1 means they haven't broken the streak
      return streak;
    }

    return 0; // Streak broken
  }

  static Future<void> recordActivity() async {
    final lastActiveStr = _storage.getData('last_active_date') as String?;
    final streak = _storage.getData('current_streak') as int? ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastActiveStr == null) {
      await _storage.saveData('last_active_date', today.toIso8601String());
      await _storage.saveData('current_streak', 1);
      return;
    }

    final lastActive = DateTime.parse(lastActiveStr);
    final lastActiveDay = DateTime(
      lastActive.year,
      lastActive.month,
      lastActive.day,
    );

    final difference = today.difference(lastActiveDay).inDays;

    if (difference == 1) {
      // Increment streak
      await _storage.saveData('last_active_date', today.toIso8601String());
      await _storage.saveData('current_streak', streak + 1);
    } else if (difference > 1) {
      // Reset streak
      await _storage.saveData('last_active_date', today.toIso8601String());
      await _storage.saveData('current_streak', 1);
    }
  }
}
