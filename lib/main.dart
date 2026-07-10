import 'package:color_sort_master/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games_services/games_services.dart';
import 'app_navigator.dart';
import 'services/challenge_deep_link_service.dart';
import 'services/ads_service.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/sound_service.dart';
import 'services/cloud_save_service.dart'; // Adicionada a chamada do arquivo de salvamento na nuvem
import 'pouring_demo.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ChallengeDeepLinkService.init();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await MobileAds.instance.initialize();
  await AdsService.initialize();
  // await SoundService.playBackgroundMusic();

  SoundService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
    _signInToGooglePlayGames();
  }

  // Função de login e recuperação de progresso
  Future<void> _signInToGooglePlayGames() async {
    try {
      await GameAuth.signIn();
      debugPrint("Login realizado com sucesso no Google Play Games");

      // Recupera o progresso da nuvem logo após o login!
      await CloudSaveService.loadGameDataFromCloud();

    } catch (e) {
      debugPrint("Ocorreu um erro ao fazer login no Google Play Games: $e");
    }
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      setState(() {
        _locale = Locale(languageCode);
      });
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);

    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Color Sort',
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}