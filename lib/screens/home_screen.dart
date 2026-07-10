import 'dart:async'; // Necessário para o Timer (Gerenciamento assíncrono do ciclo de vida)
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:color_sort_master/screens/game_screen.dart';
import 'package:color_sort_master/screens/level_select_screen.dart';
import 'package:color_sort_master/screens/challenge_screen.dart';
import 'package:color_sort_master/screens/store_screen.dart';

import 'package:color_sort_master/services/ads_service.dart';
import 'package:color_sort_master/services/save_service.dart';
import 'package:color_sort_master/services/sound_service.dart';
import 'package:color_sort_master/services/analytics_service.dart';
import 'package:color_sort_master/services/mission_service.dart';

import '../main.dart';
import '../services/hearts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPlayerLevel = 1;
  int coins = 0;
  int hearts = 0;

  bool musicEnabled = true;
  bool sfxEnabled = true;

  // Variáveis de estado para sistema de missões e controle de temporizadores (Gamification tracking)
  int levelsPlayedToday = 0;
  DateTime? adFreeEndTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadPlayerLevel();
    _loadAudioSettings();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Prevenção de Memory Leaks: Liberação explícita de recursos de background ao destruir a tela
    super.dispose();
  }

  Future<void> _loadAudioSettings() async {
    final mEnabled = await SoundService.isMusicEnabled();

    if (!mounted) return;

    setState(() {
      musicEnabled = mEnabled;
      sfxEnabled = !SoundService.isSfxMuted;
    });

    if (mEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        SoundService.playBackgroundMusic();
      });
    }
  }

  Future<void> _loadPlayerLevel() async {
    // 1. Variável de estado mutável (var) para permitir a reatribuição durante a sincronização de dados
    var profile = await SaveService.loadProfile();

    // 💡 2. Ponto de sincronização crítica: Recálculo offline (Retroactive Sync) para regeneração do sistema de energia (Hearts)
    profile = await HeartsService.syncHearts(profile);

    final todayCount = await MissionService.getPlayedTodayCount();
    final endTime = await MissionService.getAdFreeEndTime();

    if (!mounted) return;

    // ⬇️ Execução do fluxo original mantida intacta (Preparação para reatividade via setState) ⬇️

    setState(() {
      currentPlayerLevel = profile.currentLevel;
      coins = profile.coins;
      hearts = profile.hearts;
      levelsPlayedToday = todayCount;
      adFreeEndTime = endTime;
    });

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (adFreeEndTime != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (DateTime.now().isAfter(adFreeEndTime!)) {
              adFreeEndTime = null;
              levelsPlayedToday = 0;
              timer.cancel();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main_scene.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, loc),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/logo_game_title.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 15),
                _buildLevelProgress(loc),
                const Spacer(),

                // Componente dinâmico de retenção: Banner de missões ou timer inteligente (Engajamento do usuário)
                _buildAdFreeMissionBanner(context, loc),
                const SizedBox(height: 15),

                _buildContinueButton(context, loc),
                const SizedBox(height: 20),
                _buildBottomMenu(context, loc),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdFreeMissionBanner(BuildContext context, AppLocalizations loc) {
    bool isAdFree = adFreeEndTime != null;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdFree
              ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
              : [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isAdFree ? Colors.greenAccent : Colors.pinkAccent).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  isAdFree ? Icons.check_circle : Icons.block,
                  color: Colors.white,
                  size: 20
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isAdFree ? loc.adFreeActive : loc.adFreeMissionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (isAdFree)
            Text(
              _formatRemainingTime(adFreeEndTime!),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))]
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (levelsPlayedToday / 15).clamp(0.0, 1.0),
                backgroundColor: Colors.white30,
                color: Colors.amber,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "$levelsPlayedToday / 15 ${loc.adFreeMissionProgress}",
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ]
        ],
      ),
    );
  }

  String _formatRemainingTime(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(remaining.inHours)}:${twoDigits(remaining.inMinutes.remainder(60))}:${twoDigits(remaining.inSeconds.remainder(60))}";
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildStatBadge(Icons.monetization_on, Colors.amber, coins.toString()),
              const SizedBox(width: 10),
              _buildStatBadge(Icons.favorite, Colors.redAccent, hearts.toString()),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 30),
            onPressed: () {
              _showSettingsSheet(context, loc);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color iconColor, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(AppLocalizations loc) {
    return SizedBox(
      width: 250,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/bg_level_progress.png',
            fit: BoxFit.contain,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${loc.level} $currentPlayerLevel",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, AppLocalizations loc) {
    return GestureDetector(
      onTap: () async {

        // 💡 1. Validação de regras de negócio (Pre-condition guard): Bloqueia o roteamento se o saldo de energia for insuficiente
        if (hearts <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.noHearts), // Integração com i18n para feedback contextualizado
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return; // Early return para evitar execução desnecessária e proteger o estado
        }

        // 💡 2. Happy Path: Registro analítico e navegação segura após aprovação nas regras de negócio
        await FirebaseAnalytics.instance.logEvent(
          name: 'level_start',
          parameters: {'level_number': currentPlayerLevel},
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(startLevel: currentPlayerLevel),
          ),
        );

        _loadPlayerLevel();
      },
      child: SizedBox(
        width: 330,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/btn_continue_bg.png',
              fit: BoxFit.contain,
              width: 330,
            ),
            Positioned(
              top: 25,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                      const SizedBox(width: 8),
                      Text(
                        loc.continueButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${loc.level} $currentPlayerLevel",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMenuIcon(
            context,
            'assets/images/ic_menu_levels.png',
            loc.levels,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LevelSelectScreen(),
                ),
              );
            },
          ),
          _buildMenuIcon(
            context,
            'assets/images/ic_menu_store.png',
            loc.store,
                () async {
              await AnalyticsService.logStoreOpen(
                coins: coins,
                hearts: hearts,
              );

              if (!context.mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoreScreenWrapper(),
                ),
              );

              _loadPlayerLevel();
            },
          ),
          _buildMenuIcon(
            context,
            'assets/images/ic_menu_reward.png',
            loc.reward,
                () async {
              await FirebaseAnalytics.instance.logEvent(
                name: 'home_reward_ad_clicked',
              );

              AdsService.showRewarded(
                onRewarded: () async {
                  final profile = await SaveService.loadProfile();

                  final updatedProfile = profile.copyWith(
                    coins: profile.coins + 200,
                    totalCoinsEarned: profile.totalCoinsEarned + 200,
                  );

                  await SaveService.saveProfile(updatedProfile);

                  if (!mounted) return;

                  setState(() {
                    coins = updatedProfile.coins;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.rewardCoins),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onFailed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.adNotReady),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              );
            },
          ),
          _buildMenuIcon(
            context,
            'assets/images/ic_menu_missions.png',
            loc.challenge,
                () async {
              await AnalyticsService.logChallengeScreenOpen();

              if (!context.mounted) return;

              showDialog(
                context: context,
                builder: (_) => ChallengeScreen(
                  currentLevel: currentPlayerLevel,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(
      BuildContext context,
      String imagePath,
      String label,
      VoidCallback onTap,
      ) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.3),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Column(
              children: [
                Image.asset(
                  imagePath,
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C1B4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.settings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                SwitchListTile(
                  activeColor: Colors.amber,
                  secondary: Icon(
                    musicEnabled ? Icons.music_note : Icons.music_off,
                    color: Colors.amber,
                  ),
                  title: Text(
                    musicEnabled ? 'Music: ON' : 'Music: OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  value: musicEnabled,
                  onChanged: (value) async {
                    await SoundService.setMusicEnabled(value);

                    if (!mounted) return;

                    setState(() {
                      musicEnabled = value;
                    });

                    Navigator.pop(context);
                    _showSettingsSheet(context, loc);
                  },
                ),

                SwitchListTile(
                  activeColor: Colors.amber,
                  secondary: Icon(
                    sfxEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.amber,
                  ),
                  title: Text(
                    sfxEnabled ? 'SFX: ON' : 'SFX: OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  value: sfxEnabled,
                  onChanged: (value) {
                    SoundService.isSfxMuted = !value;

                    if (mounted) {
                      setState(() {
                        sfxEnabled = value;
                      });
                    }

                    Navigator.pop(context);
                    _showSettingsSheet(context, loc);
                  },
                ),

                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.amber),
                  title: Text(
                    loc.language,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                _buildLanguageTile(
                  context,
                  flag: "🇺🇸",
                  title: loc.english,
                  locale: const Locale('en'),
                ),
                _buildLanguageTile(
                  context,
                  flag: "🇧🇷",
                  title: loc.portuguese,
                  locale: const Locale('pt'),
                ),
                _buildLanguageTile(
                  context,
                  flag: "🇸🇦",
                  title: loc.arabic,
                  locale: const Locale('ar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, {
        required String flag,
        required String title,
        required Locale locale,
      }) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 26)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      onTap: () {
        MyApp.setLocale(context, locale);
        Navigator.pop(context);
      },
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF2C1B4D),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, color: Colors.amber, size: 80),
            const SizedBox(height: 20),
            Text(
              '$title Screen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              loc.comingSoon,
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}