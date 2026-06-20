import 'package:hive/hive.dart';
import 'package:vortex_dashboard/models/gps_data.dart';

part 'ride_model.g.dart';

@HiveType(typeId: 0)
class RideModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime? endTime;

  @HiveField(3)
  final double distanceKm;

  @HiveField(4)
  final double maxSpeedKmh;

  @HiveField(5)
  final double averageSpeedKmh;

  @HiveField(6)
  final double maxAltitude;

  @HiveField(7)
  final double minAltitude;

  @HiveField(8)
  final List<GpsData> trackPoints;

  @HiveField(9)
  final String? name;

  @HiveField(10)
  final double? startLatitude;

  @HiveField(11)
  final double? startLongitude;

  @HiveField(12)
  final double? endLatitude;

  @HiveField(13)
  final double? endLongitude;

  RideModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0,
    this.maxSpeedKmh = 0,
    this.averageSpeedKmh = 0,
    this.maxAltitude = 0,
    this.minAltitude = double.infinity,
    this.trackPoints = const [],
    this.name,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  bool get isComplete => endTime != null;

  RideModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceKm,
    double? maxSpeedKmh,
    double? averageSpeedKmh,
    double? maxAltitude,
    double? minAltitude,
    List<GpsData>? trackPoints,
    String? name,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
  }) {
    return RideModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceKm: distanceKm ?? this.distanceKm,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      minAltitude: minAltitude ?? this.minAltitude,
      trackPoints: trackPoints ?? this.trackPoints,
      name: name ?? this.name,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distanceKm': distanceKm,
      'maxSpeedKmh': maxSpeedKmh,
      'averageSpeedKmh': averageSpeedKmh,
      'maxAltitude': maxAltitude,
      'minAltitude': minAltitude == double.infinity ? 0 : minAltitude,
      'trackPoints': trackPoints.map((p) => p.toJson()).toList(),
      'name': name,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
    };
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
      maxAltitude: (json['maxAltitude'] as num).toDouble(),
      minAltitude: (json['minAltitude'] as num).toDouble(),
      trackPoints: (json['trackPoints'] as List)
          .map((p) => GpsData.fromJson(p as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String?,
      startLatitude: (json['startLatitude'] as num?)?.toDouble(),
      startLongitude: (json['startLongitude'] as num?)?.toDouble(),
      endLatitude: (json['endLatitude'] as num?)?.toDouble(),
      endLongitude: (json['endLongitude'] as num?)?.toDouble(),
    );
  }

  String toGpx() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="VortexDashboard"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${name ?? "Vortex Ride"}</name>');
    buffer.writeln('    <trkseg>');

    for (final point in trackPoints) {
      buffer.writeln(
        '      <trkpt lat="${point.latitude}" lon="${point.longitude}">',
      );
      buffer.writeln('        <ele>${point.altitude}</ele>');
      buffer.writeln('        <time>${point.timestamp.toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('latitude,longitude,altitude,speed,heading,timestamp');
    for (final point in trackPoints) {
      buffer.writeln(
        '${point.latitude},${point.longitude},${point.altitude},${point.speed},${point.heading},${point.timestamp.toIso8601String()}',
      );
    }
    return buffer.toString();
  }
}
