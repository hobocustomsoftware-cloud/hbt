import 'package:flutter/material.dart';

import 'core/theme/hbt_theme.dart';
import 'features/design_system/design_system_showcase.dart';

/// Design System validation entry point (separate web target).
///
/// Runs [DesignSystemShowcase] with the HBT brand theme so the responsive
/// design system can be validated at every breakpoint without touching
/// feature logic. Build: `flutter build web -t lib/main_design_system.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DesignSystemApp());
}

class _DesignSystemApp extends StatelessWidget {
  const _DesignSystemApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HBT Design System',
      debugShowCheckedModeBanner: false,
      theme: HbtTheme.light(),
      darkTheme: HbtTheme.dark(),
      home: const DesignSystemShowcase(),
    );
  }
}
