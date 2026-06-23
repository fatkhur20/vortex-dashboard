import 'package:flutter/material.dart';

enum MapStyleLabel { satelliteHybrid, streets, dark, outdoors, custom }

extension MapStyleLabelX on MapStyleLabel {
  String get uri {
    switch (this) {
      case MapStyleLabel.satelliteHybrid:
        return 'mapbox://styles/chenaa/cmqp68cnn00cq01s58inog2f6';
      case MapStyleLabel.streets:
        return 'mapbox://styles/mapbox/streets-v12';
      case MapStyleLabel.dark:
        return 'mapbox://styles/mapbox/dark-v11';
      case MapStyleLabel.outdoors:
        return 'mapbox://styles/chenaa/cmqp5uhlz000g01qmhycg6m9q';
      case MapStyleLabel.custom:
        return 'mapbox://styles/mapbox/streets-v12';
    }
  }

  String get label {
    switch (this) {
      case MapStyleLabel.satelliteHybrid: return 'Hybrid';
      case MapStyleLabel.streets: return 'Streets';
      case MapStyleLabel.dark: return 'Dark';
      case MapStyleLabel.outdoors: return 'Outdoors';
      case MapStyleLabel.custom: return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case MapStyleLabel.satelliteHybrid: return Icons.satellite_alt;
      case MapStyleLabel.streets: return Icons.light_mode;
      case MapStyleLabel.dark: return Icons.dark_mode;
      case MapStyleLabel.outdoors: return Icons.terrain;
      case MapStyleLabel.custom: return Icons.palette;
    }
  }
}
