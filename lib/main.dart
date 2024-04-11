import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prsample/screens/splash_screen.dart';
import 'package:prsample/utils/themes.dart';

GlobalKey<NavigatorState> navKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
  ));
  if (await Permission.storage.isDenied) {
    Permission.storage.request().then((value) {
      value.isDenied ? exit(0) : null;
    });
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // FFmpegKitConfig.setFontconfigConfigurationPath(path);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      theme: CustomTheme.lightTheme(context),
      darkTheme: CustomTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home:  const SplashScreen()
    );
  }
}
