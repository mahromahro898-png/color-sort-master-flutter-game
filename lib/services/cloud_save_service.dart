/// ══════════════════════════════════════════════════════════
///  cloud_save_service.dart
///  Serviço de Persistência em Nuvem - Integração com Google Play Games, sincronização de estado e resolução de conflitos de dados
/// ══════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';

import 'save_service.dart';

class CloudSaveService {
  CloudSaveService._();

  static const String _saveSlotName = 'color_sort_master_save';

  static bool _isInitializing = false;
  static bool _isReady = false;
  static DateTime? _lastFailedAttempt;

  // Implementação do padrão Circuit Breaker mitigado: Evita chamadas repetitivas de API em caso de falhas recentes
  static Future<bool> _ensureReady() async {
    if (_isReady) return true;

    if (_isInitializing) {
      return false;
    }

    final lastFailed = _lastFailedAttempt;
    if (lastFailed != null &&
        DateTime.now().difference(lastFailed).inMinutes < 5) {
      debugPrint('☁️ Cloud Save ignorado: Falha recente detectada no Google Play Games (Circuit Breaker aplicado).');
      return false;
    }

    _isInitializing = true;

    try {
      await GamesServices.signIn().timeout(
        const Duration(seconds: 8),
      );

      _isReady = true;
      debugPrint('☁️ Solicitação de autenticação no Google Play Games iniciada com sucesso.');
      return true;
    } on TimeoutException {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();
      debugPrint('⚠️ Timeout na autenticação do Google Play Games (Prevenção de bloqueio da UI thread).');
      return false;
    } catch (e, stack) {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();

      debugPrint('⚠️ Falha na autenticação do Google Play Games (Exception Handled): $e');
      debugPrintStack(stackTrace: stack);

      return false;
    } finally {
      _isInitializing = false;
    }
  }

  // Serialização de dados e persistência remota (Snapshot do estado do jogador)
  static Future<void> saveGameDataToCloud() async {
    try {
      final ready = await _ensureReady();
      if (!ready) return;

      final profile = await SaveService.loadProfile();

      final gameData = {
        'currentLevel': profile.currentLevel,
        'highestUnlockedLevel': profile.highestUnlockedLevel,
        'coins': profile.coins,
        'hearts': profile.hearts,
        'hintsCount': profile.hintsCount,
        'undosCount': profile.undosCount,
        'extraTubesCount': profile.extraTubesCount,
        'totalLevelsCompleted': profile.totalLevelsCompleted,
        'totalCoinsEarned': profile.totalCoinsEarned,
        'savedAt': DateTime.now().toIso8601String(),
      };

      final dataString = jsonEncode(gameData);

      await SaveGame.saveGame(
        data: dataString,
        name: _saveSlotName,
      ).timeout(const Duration(seconds: 8));

      debugPrint('☁️ Sucesso na persistência de dados em nuvem (Cloud Save): $dataString');
    } on TimeoutException {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();
      debugPrint('⚠️ Timeout durante a operação de salvamento em nuvem.');
    } catch (e, stack) {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();

      debugPrint('⚠️ Erro na operação de salvamento em nuvem: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  // Sincronização de dados remotos e lógica de reconciliação (Data Reconciliation)
  static Future<void> loadGameDataFromCloud() async {
    try {
      final ready = await _ensureReady();
      if (!ready) return;

      final result = await SaveGame.loadGame(
        name: _saveSlotName,
      ).timeout(const Duration(seconds: 8));

      if (result == null || result.isEmpty) {
        debugPrint('☁️ Nenhum dado de salvamento em nuvem encontrado (Inicializando state local).');
        return;
      }

      final decoded = jsonDecode(result);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('☁️ Falha de validação: Formato de salvamento em nuvem inválido ou corrompido.');
        return;
      }

      // Fallback seguro para chaves legadas e extração sanitizada de dados
      final cloudLevel = _readInt(decoded['currentLevel']) ??
          _readInt(decoded['level']) ??
          1;

      final cloudCoins = _readInt(decoded['coins']) ?? 0;

      final localProfile = await SaveService.loadProfile();

      // Resolução de Conflitos (Conflict Resolution): Prioriza sempre o progresso mais avançado do jogador
      if (cloudLevel > localProfile.currentLevel) {
        final updatedProfile = localProfile.copyWith(
          currentLevel: cloudLevel,
          highestUnlockedLevel: cloudLevel > localProfile.highestUnlockedLevel
              ? cloudLevel
              : localProfile.highestUnlockedLevel,
          coins: cloudCoins > localProfile.coins
              ? cloudCoins
              : localProfile.coins,
        );

        await SaveService.saveProfile(updatedProfile);
        await SaveService.saveLevel(cloudLevel);

        debugPrint('☁️ Salvamento em nuvem carregado e estado sincronizado com sucesso. Nível atualizado: $cloudLevel');
      } else {
        debugPrint('📱 Resolução de Conflito: O salvamento local é mais recente ou equivalente (Merge em nuvem ignorado).');
      }
    } on TimeoutException {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();
      debugPrint('⚠️ Timeout na leitura do salvamento em nuvem.');
    } catch (e, stack) {
      _isReady = false;
      _lastFailedAttempt = DateTime.now();

      debugPrint('⚠️ Erro durante o carregamento de dados da nuvem: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  // Parser utilitário (Type-safe parsing) para evitar exceções de cast implícito
  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}