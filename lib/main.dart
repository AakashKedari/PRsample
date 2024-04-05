import 'dart:io';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prsample/screens/drag_screen.dart';
import 'package:prsample/screens/splash_screen.dart';
import 'package:prsample/screens/textoverlayscreen.dart';
import 'package:prsample/screens/two_audio.dart';
import 'package:prsample/themes.dart';

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
  FFmpegKitConfig.setFontDirectory('/system/fonts');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme.lightTheme(context),
      // Call the method with context
      darkTheme: CustomTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home:  SplashScreen(),
    );
  }
}

