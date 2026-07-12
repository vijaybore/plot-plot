import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for online multiplayer (Realtime Database sync + chat).
  // firebase_options.dart is a placeholder until `flutterfire configure`
  // is run — guarded so offline pass-and-play still works either way;
  // only the Online mode actually needs this to have succeeded.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Falls through — Online mode will show its own error if tapped
    // before Firebase is configured.
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: PlotPlotApp()));
}

class PlotPlotApp extends StatelessWidget {
  const PlotPlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot Plot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // The board, dice, and HUD cards use tightly fixed pixel sizes to fit
      // a lot of live game data into a small mobile screen. Left unclamped,
      // a user's system "large text" accessibility setting can multiply
      // every label past what those cards were built to hold, producing
      // RenderFlex "OVERFLOWED BY n PIXELS" errors under player names, the
      // Bank balance row, and empty-plot cards. Clamping (not disabling)
      // text scale keeps things legible while guaranteeing the HUD never
      // breaks layout.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
          ),
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}