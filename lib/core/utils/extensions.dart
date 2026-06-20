import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

extension SpeedColor on double {
  Color get speedColor {
    if (this < 60) return ThemeConstants.speedLow;
    if (this < 100) return ThemeConstants.speedMedium;
    if (this < 140) return ThemeConstants.speedHigh;
    return ThemeConstants.speedCritical;
  }

  String get speedColorHex {
    return '#${speedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

extension DurationFormat on Duration {
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get shortFormat {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension DateTimeFormat on DateTime {
  String get dateFormatted => DateFormat('MMM dd, yyyy').format(this);
  String get timeFormatted => DateFormat('HH:mm:ss').format(this);
  String get dateTimeFormatted => DateFormat('MMM dd, yyyy HH:mm').format(this);
  String get fileFormatted => DateFormat('yyyyMMdd_HHmmss').format(this);
}

extension NumFormat on num {
  String get oneDecimal => toStringAsFixed(1);
  String get twoDecimal => toStringAsFixed(2);
  String get noDecimal => toStringAsFixed(0);
}
