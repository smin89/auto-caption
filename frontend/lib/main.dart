import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:window_manager/window_manager.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await acrylic.Window.initialize();

  runApp(const AutoCaptionApp());

  const windowOptions = WindowOptions(
    size: Size(900, 500),
    minimumSize: Size(500, 200),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.setResizable(true);
    await windowManager.setAlwaysOnTop(true);

    await acrylic.Window.setEffect(effect: acrylic.WindowEffect.transparent);

    await windowManager.show();
    await windowManager.focus();
  });
}

class AutoCaptionApp extends StatelessWidget {
  const AutoCaptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Caption',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: const HomeScreen(),
    );
  }
}
