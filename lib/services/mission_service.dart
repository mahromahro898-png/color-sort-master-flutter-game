import 'package:shared_preferences/shared_preferences.dart';

class MissionService {
  static const String _keyPlayedToday = 'mission_played_today';
  static const String _keyLastDate = 'mission_last_date';
  static const String _keyAdFreeUntil = 'mission_ad_free_until';

  /// Função chamada ao vencer a fase para incrementar o contador
  static Future<void> incrementLevelCount() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0]; // Formato: YYYY-MM-DD
    final lastDate = prefs.getString(_keyLastDate) ?? '';

    int playedToday = prefs.getInt(_keyPlayedToday) ?? 0;

    // Se a data mudou desde a última vez que jogou, zera o contador para o novo dia
    if (lastDate != todayStr) {
      playedToday = 1;
    } else {
      playedToday++;
    }

    await prefs.setString(_keyLastDate, todayStr);
    await prefs.setInt(_keyPlayedToday, playedToday);

    // Se atingir a meta (15 fases), concede 24 horas sem anúncios
    if (playedToday == 15) {
      final adFreeUntil = DateTime.now().add(const Duration(hours: 24));
      await prefs.setString(_keyAdFreeUntil, adFreeUntil.toIso8601String());
    }
  }

  /// Obtém o número de fases que o jogador concluiu hoje
  static Future<int> getPlayedTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString(_keyLastDate) ?? '';

    if (lastDate != todayStr) {
      return 0; // Novo dia, o contador é zero programaticamente até ser atualizado
    }
    return prefs.getInt(_keyPlayedToday) ?? 0;
  }

  /// Verifica se o recurso "sem anúncios" está ativo (as 24 horas ainda estão rolando?)
  static Future<bool> isAdFreeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeUntilStr = prefs.getString(_keyAdFreeUntil);
    if (adFreeUntilStr == null) return false;

    final adFreeUntil = DateTime.parse(adFreeUntilStr);
    // Se o tempo atual for anterior ao tempo de expiração, os anúncios estão desativados
    return DateTime.now().isBefore(adFreeUntil);
  }

  /// Obtém o tempo de término do recurso "sem anúncios" para exibição no cronômetro
  static Future<DateTime?> getAdFreeEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeUntilStr = prefs.getString(_keyAdFreeUntil);
    if (adFreeUntilStr == null) return null;

    final adFreeUntil = DateTime.parse(adFreeUntilStr);
    if (DateTime.now().isBefore(adFreeUntil)) {
      return adFreeUntil;
    }
    return null; // O tempo expirou
  }
}