extension ToTimeString on int? {
  String get toDateStringPrefRelative {
    if (this == null) {
      return 'never';
    }
    // Assumes the integer is a Unix timestamp in milliseconds
    final DateTime eventTime = DateTime.fromMillisecondsSinceEpoch(this!);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(eventTime);

    // Handle future timestamps or very recent actions
    if (difference.isNegative || difference.inSeconds < 5) {
      return 'Just now';
    }
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }

    // Check if the event happened yesterday
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (eventTime.year == yesterday.year &&
        eventTime.month == yesterday.month &&
        eventTime.day == yesterday.day) {
      return 'Yesterday';
    }

    // Switch to absolute date for anything older than yesterday
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    }

    // Return absolute standard date (YYYY-MM-DD)
    return '${eventTime.month.toString().padLeft(2, '0')} ${eventTime.day.toString().padLeft(2, '0')} ${eventTime.year}';
  }

  String get toDateStringPrefRelativeShort {
    String res = toDateStringPrefRelative;

    final DateTime eventTime = DateTime.fromMillisecondsSinceEpoch(this!);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(eventTime);

    final parts = res.split(" ");

    if (difference.inDays > 30) {
      return parts.take(2).join(" ");
    }

    return "${parts.first}${parts[1][0]} ${parts[2]}";
  }
}
