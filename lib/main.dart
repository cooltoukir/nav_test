import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nav_test/core/utils/app_constants.dart';
import 'package:nav_test/features/map/screens/map_screen.dart';
import 'package:toastification/toastification.dart';

import 'config/flavor_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ToastificationWrapper(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flavorConfigProvider);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      builder: (context, child) {
        if (!config.isDev) return child!;
        return Banner(
          message: AppConstants.dev,
          location: BannerLocation.topEnd,
          color: Colors.red,
          child: child!,
        );
      },
      home: MapScreen(),
    );
  }
}
