import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_constants.dart';

enum Flavor { dev, prod }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String osrmBaseUrl;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.osrmBaseUrl,
  });

  bool get isDev => flavor == Flavor.dev;

  static const _dev = FlavorConfig(
    flavor: Flavor.dev,
    appName: AppConstants.devAppName,
    osrmBaseUrl: AppConstants.devOsrmBaseUrl,
  );

  static const _prod = FlavorConfig(
    flavor: Flavor.prod,
    appName: AppConstants.prodAppName,
    osrmBaseUrl: AppConstants.prodOsrmBaseUrl,
  );

  factory FlavorConfig.fromFlavor() {
    switch (appFlavor) {
      case 'dev':
        return _dev;
      case 'prod':
        return _prod;
      default:
        return _dev;
    }
  }
}

final flavorConfigProvider = Provider<FlavorConfig>(
  (ref) => FlavorConfig.fromFlavor(),
);
