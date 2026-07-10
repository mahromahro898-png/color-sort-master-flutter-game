# 🧪 Color Sort Master - Jogo de Quebra-Cabeça

Um jogo de quebra-cabeça lógico e cativante desenvolvido em **Flutter**. O objetivo é classificar as cores nos tubos de vidro até que cada tubo contenha apenas uma cor. Este projeto foi construído com foco em **Código Limpo (Clean Code)**, animações fluidas e uma excelente experiência do usuário (UX).

## 🚀 Funcionalidades Principais

*   **Animações Personalizadas:** Uso avançado de `CustomPainter` e `AnimationController` para simular o fluxo de água e o movimento dos tubos de forma realista.
*   **Sistema de Salvamento na Nuvem:** Integração com **Google Play Games Services** para manter o progresso do jogador seguro e sincronizado.
*   **Internacionalização (i18n):** Suporte nativo para Português (PT-BR), Inglês e Árabe, demonstrando boas práticas de localização.
*   **Música e Efeitos Sonoros:** Controle completo de áudio usando o pacote `audioplayers` com gerenciamento de ciclo de vida do aplicativo (pausa/retoma automaticamente).
*   **Geração Dinâmica de Níveis:** Um algoritmo inteligente (`LevelDifficultyCurve`) que gera fases com dificuldade progressiva sem comprometer o desempenho.
*   **Integração com Firebase & Ads:** Monitoramento de estabilidade com **Firebase Crashlytics** e monetização configurada via **Google Mobile Ads**.

## 🛠️ Tecnologias e Pacotes Utilizados

*   [Flutter](https://flutter.dev/) & Dart
*   `shared_preferences` (Armazenamento local)
*   `firebase_core` & `firebase_crashlytics` (Backend e estabilidade)
*   `google_mobile_ads` (Monetização)
*   `audioplayers` (Gerenciamento de som)
*   `flutter_localizations` (Suporte a múltiplos idiomas)
*   `games_services` (Autenticação e Cloud Save)

## 📱 Como Executar o Projeto

Para testar o jogo em sua máquina local, siga os passos abaixo:

1. Clone este repositório:
   ```bash
   git clone [https://github.com/mahromahro898-png/color-sort-master-flutter-game.git](https://github.com/mahromahro898-png/color-sort-master-flutter-game.git)