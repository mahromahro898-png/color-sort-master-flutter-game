// ============================================================
// store_screen.dart
// Pronto para integração com Google Play Billing (IAP) e suporte a Internacionalização (i18n)
// ============================================================
import 'package:flutter/material.dart';

// Importação do gerenciador de compras (StoreManager) contendo a lógica de negócios de In-App Purchases
import 'store_manager.dart';

// Descomente a linha abaixo caso opte por utilizar a biblioteca de IAP diretamente na camada de UI (não recomendado por princípios de Clean Architecture):
// import 'package:in_app_purchase/in_app_purchase.dart';

// ─────────────────────────────────────────────
// TRANSLATIONS (Dicionário de Internacionalização - i18n para suporte multilíngue)
// ─────────────────────────────────────────────
class _T {
  static const Map<String, Map<String, String>> _d = {
    'en': {
      'store_title': 'Store',
      'close': 'Close',
      'section_packs': 'Magic Packs',
      'section_coins': 'Coins',
      'starter_pack': 'Starter Pack',
      'pack_2k': 'Pack 2000',
      'pack_4k': 'Pack 4000',
      'pack_8k': 'Pack 8000',
    },
    'pt': {
      'store_title': 'Loja',
      'close': 'Fechar',
      'section_packs': 'Pacotes Mágicos',
      'section_coins': 'Moedas',
      'starter_pack': 'Pacote Inicial',
      'pack_2k': 'Pacote 2000',
      'pack_4k': 'Pacote 4000',
      'pack_8k': 'Pacote 8000',
    },
    'ar': {
      'store_title': 'المتجر',
      'close': 'إغلاق',
      'section_packs': 'الحزم السحرية',
      'section_coins': 'العملات',
      'starter_pack': 'حزمة الخصم',
      'pack_2k': 'حزمة 2000',
      'pack_4k': 'حزمة 4000',
      'pack_8k': 'حزمة 8000',
    },
  };

  static String call(BuildContext ctx, String key) {
    // Ponto de injeção para bibliotecas de internacionalização avançadas (ex: GetX, intl ou flutter_localizations)
    // Fallback temporário: Resolução do locale com base nas configurações de idioma do dispositivo (Device Locale):
    final lang = Localizations.localeOf(ctx).languageCode;
    return _d[lang]?[key] ?? _d['en']![key] ?? key;
  }
}

String tr(BuildContext ctx, String key) => _T.call(ctx, key);

// ─────────────────────────────────────────────
// DATA MODELS (Estruturas de dados imutáveis contendo os preços padrão de fallback)
// ─────────────────────────────────────────────
class PackData {
  const PackData({
    required this.imagePath,
    required this.nameKey,
    required this.defaultPrice,
    required this.productId,
  });

  final String imagePath;
  final String nameKey;
  final String defaultPrice;
  final String productId;
}

class CoinData {
  const CoinData({
    required this.amount,
    required this.defaultPrice,
    required this.productId
  });

  final int amount;
  final String defaultPrice;
  final String productId;
}

// ── Coordenadas de layout para o posicionamento absoluto de texto nos cartões (UI Mapping) ───────────
const double _kBarTop = 0.70;
const double _kBarBottom = 0.815;
const double _kBlueLeft = 0.07;
const double _kBlueRight = 0.475;
const double _kGreenLeft = 0.515;
const double _kGreenRight = 0.935;

// ── Mock de dados: Catálogo de Pacotes e Moedas (Soft/Hard Currency) ────────────────────────
const List<PackData> _packs = [
  PackData(
    imagePath: 'assets/store/starter_pack.png',
    nameKey: 'starter_pack',
    defaultPrice: 'R\$ 3.99',
    productId: 'com.game.pack.1000', // Product ID (SKU) estritamente mapeado com a Google Play Console
  ),
  PackData(
    imagePath: 'assets/store/pack_2000.png',
    nameKey: 'pack_2k',
    defaultPrice: 'R\$ 19.99',
    productId: 'com.game.pack.2000',
  ),
  PackData(
    imagePath: 'assets/store/pack_4000.png',
    nameKey: 'pack_4k',
    defaultPrice: 'R\$ 39.99',
    productId: 'com.game.pack.4000',
  ),
  PackData(
    imagePath: 'assets/store/pack_8000.png',
    nameKey: 'pack_8k',
    defaultPrice: 'R\$ 79.99',
    productId: 'com.game.pack.8000',
  ),
];

const List<CoinData> _coins = [
  CoinData(amount: 1000, defaultPrice: 'R\$ 5.00', productId: 'com.game.coins.1000'),
  CoinData(amount: 2000, defaultPrice: 'R\$ 8.00', productId: 'com.game.coins.2000'),
  CoinData(amount: 5000, defaultPrice: 'R\$ 20.00', productId: 'com.game.coins.5000'),
  CoinData(amount: 10000, defaultPrice: 'R\$ 35.00', productId: 'com.game.coins.10000'),
  CoinData(amount: 25000, defaultPrice: 'R\$ 65.00', productId: 'com.game.coins.25000'),
  CoinData(amount: 50000, defaultPrice: 'R\$ 100.00', productId: 'com.game.coins.50000'),
];

// ─────────────────────────────────────────────
// WIDGETS (Componentes de UI isolados para maximizar a reutilização e performance)
// ─────────────────────────────────────────────
class GamePackWidget extends StatefulWidget {
  const GamePackWidget({
    super.key,
    required this.data,
    required this.displayPrice,
    required this.onPurchasePressed,
  });

  final PackData data;
  final String displayPrice; // Preço dinâmico resolvido (Pode ser o preço localizado da loja ou o fallback)
  final void Function(String productId) onPurchasePressed;

  @override
  State<GamePackWidget> createState() => _GamePackWidgetState();
}

class _GamePackWidgetState extends State<GamePackWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 80),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onPurchasePressed(widget.data.productId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _ctrl,
        child: LayoutBuilder(
          builder: (context, box) {
            final W = box.maxWidth;
            final H = box.maxHeight;

            final barTop = H * _kBarTop;
            final barH = H * (_kBarBottom - _kBarTop);
            final blueLeft = W * _kBlueLeft;
            final blueW = W * (_kBlueRight - _kBlueLeft);
            final greenLeft = W * _kGreenLeft;
            final greenW = W * (_kGreenRight - _kGreenLeft);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(widget.data.imagePath, fit: BoxFit.fill),
                  ),
                ),
                Positioned(
                  left: blueLeft, top: barTop, width: blueW, height: barH,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: W * 0.02),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr(context, widget.data.nameKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900,
                            shadows: [Shadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 1))],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: greenLeft, top: barTop, width: greenW, height: barH,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: W * 0.02),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.displayPrice, // Preço renderizado (Localizado)
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900,
                            shadows: [Shadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 1))],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoinCard extends StatefulWidget {
  const _CoinCard({required this.data, required this.displayPrice, required this.onPressed});

  final CoinData data;
  final String displayPrice; // Preço renderizado na UI (Localizado)
  final VoidCallback onPressed;

  @override
  State<_CoinCard> createState() => _CoinCardState();
}

class _CoinCardState extends State<_CoinCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 110),
      lowerBound: 0.93, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onPressed();
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF281F54), Color(0xFF1E1642)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.amber.withOpacity(0.08), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 42),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _fmt(widget.data.amount),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(vertical: 6),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.displayPrice, // Preço final injetado na UI
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.titleKey, required this.color});
  final String titleKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Text(
            tr(context, titleKey),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _DecorativeDivider extends StatelessWidget {
  const _DecorativeDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 1.5, width: 60, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.amber.withOpacity(0.6)]))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Icon(Icons.diamond_outlined, color: Colors.amber, size: 20)),
          Container(height: 1.5, width: 60, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.6), Colors.transparent]))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// StoreScreen (UI Base da loja - Isolada como componente interno/privado para evitar acoplamento de estado)
// ─────────────────────────────────────────────
class StoreScreen extends StatelessWidget {
  const StoreScreen({
    super.key,
    this.onPurchasePressed,
    this.livePrices = const {},
  });

  final void Function(String productId)? onPurchasePressed;
  final Map<String, String> livePrices;

  void _buy(BuildContext ctx, String id) {
    debugPrint('[Store] Initiating purchase for: $id');
    onPurchasePressed?.call(id);
  }

  String _getPrice(String productId, String defaultPrice) {
    return livePrices[productId] ?? defaultPrice;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW - 28;
    final cardH = cardW * (896 / 1195);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter, radius: 1.2,
            colors: [Color(0xFF2A1B4A), Color(0xFF0D061A)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  _SectionHeader(titleKey: 'section_packs', color: const Color(0xFF8E24AA)),

                  ...List.generate(_packs.length, (index) {
                    final p = _packs[index];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.12), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
                            ),
                            width: cardW,
                            height: cardH,
                            child: GamePackWidget(
                              data: p,
                              displayPrice: _getPrice(p.productId, p.defaultPrice), // Integração do preço em tempo real da Google Play
                              onPurchasePressed: (id) => _buy(context, id),
                            ),
                          ),
                        ),
                        if (index < _packs.length - 1) const _DecorativeDivider(),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),
                  _SectionHeader(titleKey: 'section_coins', color: const Color(0xFFD32F2F)),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
                      ),
                      itemCount: _coins.length,
                      itemBuilder: (ctx, i) => _CoinCard(
                        data: _coins[i],
                        displayPrice: _getPrice(_coins[i].productId, _coins[i].defaultPrice), // Integração do preço em tempo real da Google Play
                        onPressed: () => _buy(context, _coins[i].productId),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 10, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF150B29),
        border: Border(bottom: BorderSide(color: Colors.purpleAccent.withOpacity(0.2), width: 1)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            tr(context, 'store_title'),
            style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900,
              letterSpacing: 1.5, shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 8)],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2A1B4A), Color(0xFF1A1033)]),
                  shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// StoreScreenWrapper (Container Component - Gerencia o estado e injeta as dependências da StoreScreen)
// ─────────────────────────────────────────────
class StoreScreenWrapper extends StatefulWidget {
  const StoreScreenWrapper({super.key});

  @override
  State<StoreScreenWrapper> createState() => _StoreScreenWrapperState();
}

class _StoreScreenWrapperState extends State<StoreScreenWrapper> {
  final StoreManager _storeManager = StoreManager();

  @override
  void dispose() {
    _storeManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _storeManager,
      builder: (context, child) {
        return StoreScreen(
          // Propagação dos preços localizados em tempo real (Live Prices) via Google Play Billing
          livePrices: _storeManager.livePrices,

          // Delegação do evento de checkout para a camada de serviço (Business Logic)
          onPurchasePressed: (productId) {
            _storeManager.buyProduct(productId);
          },
        );
      },
    );
  }
}