enum UserActivity {
  stationary, walking, running, cycling, driving, unknown
}

extension UserActivityX on UserActivity {
  String get label {
    switch (this) {
      case UserActivity.stationary: return 'Stationary';
      case UserActivity.walking: return 'Walking';
      case UserActivity.running: return 'Running';
      case UserActivity.cycling: return 'Cycling';
      case UserActivity.driving: return 'Driving';
      case UserActivity.unknown: return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case UserActivity.stationary: return '📍';
      case UserActivity.walking: return '🚶';
      case UserActivity.running: return '🏃';
      case UserActivity.cycling: return '🚴';
      case UserActivity.driving: return '🚗';
      case UserActivity.unknown: return '❓';
    }
  }
}

class ActivityData {
  final UserActivity activity;
  final double confidence;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  ActivityData({
    this.activity = UserActivity.unknown,
    this.confidence = 0,
    this.speed,
    this.heading,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  static UserActivity detectFromSpeed(double speedKmh) {
    if (speedKmh < 0.5) return UserActivity.stationary;
    if (speedKmh < 6) return UserActivity.walking;
    if (speedKmh < 12) return UserActivity.running;
    if (speedKmh < 25) return UserActivity.cycling;
    return UserActivity.driving;
  }

  static double confidenceFromSpeed(double speedKmh) {
    if (speedKmh < 0.5) return speedKmh == 0 ? 0.95 : 0.8;
    if (speedKmh < 6) return 0.7;
    if (speedKmh < 12) return 0.6;
    if (speedKmh < 25) return 0.5;
    return 0.9;
  }

  ActivityData copyWith({
    UserActivity? activity, double? confidence,
    double? speed, double? heading, DateTime? timestamp,
  }) {
    return ActivityData(
      activity: activity ?? this.activity,
      confidence: confidence ?? this.confidence,
      speed: speed ?? this.speed, heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
