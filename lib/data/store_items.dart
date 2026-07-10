/// ══════════════════════════════════════════════════════════
///  store_items.dart
///  Catálogo completo de produtos da loja - Configuração centralizada para facilitar a manutenção, escalabilidade e testes A/B na monetização
/// ══════════════════════════════════════════════════════════

import '../models/store_item_model.dart';

class StoreItems {
  StoreItems._();

  // ── Coin Packs ─────────────────────────────────────────
  static final List<CoinPackItem> coinPacks = [
    CoinPackItem(
      id: 'coins_500',
      coins: 500,
      price: '\$0.99',
      productId: 'com.yourapp.coins_500',
      label: 'Small Pack',
      icon: '🪙',
    ),
    CoinPackItem(
      id: 'coins_2000',
      coins: 2000,
      price: '\$2.99',
      productId: 'com.yourapp.coins_2000',
      label: 'Popular',
      icon: '💰',
      isBestValue: false,
      isPopular: true,
    ),
    CoinPackItem(
      id: 'coins_5000',
      coins: 5000,
      price: '\$5.99',
      productId: 'com.yourapp.coins_5000',
      label: 'Best Value',
      icon: '💎',
      isBestValue: true,
    ),
    CoinPackItem(
      id: 'coins_12000',
      coins: 12000,
      price: '\$9.99',
      productId: 'com.yourapp.coins_12000',
      label: 'Mega Pack',
      icon: '👑',
    ),
  ];

  // ── Boosters ───────────────────────────────────────────
  static final List<BoosterItem> boosters = [
    BoosterItem(
      id: 'hints_3',
      type: BoosterType.hint,
      amount: 3,
      coinPrice: 250,
      label: '3 Hints',
      icon: '💡',
    ),
    BoosterItem(
      id: 'hints_10',
      type: BoosterType.hint,
      amount: 10,
      coinPrice: 700,
      label: '10 Hints',
      icon: '💡',
      isBestValue: true,
    ),
    BoosterItem(
      id: 'undos_3',
      type: BoosterType.undo,
      amount: 3,
      coinPrice: 120,
      label: '3 Undos',
      icon: '↩️',
    ),
    BoosterItem(
      id: 'undos_10',
      type: BoosterType.undo,
      amount: 10,
      coinPrice: 350,
      label: '10 Undos',
      icon: '↩️',
      isBestValue: true,
    ),
    BoosterItem(
      id: 'tubes_3',
      type: BoosterType.extraTube,
      amount: 3,
      coinPrice: 500,
      label: '3 Extra Tubes',
      icon: '🧪',
    ),
    BoosterItem(
      id: 'tubes_10',
      type: BoosterType.extraTube,
      amount: 10,
      coinPrice: 1400,
      label: '10 Extra Tubes',
      icon: '🧪',
      isBestValue: true,
    ),
    BoosterItem(
      id: 'refill_hearts',
      type: BoosterType.heartRefill,
      amount: 5,
      coinPrice: 400,
      label: 'Refill Hearts',
      icon: '❤️',
    ),
  ];

  // ── Special Offers ─────────────────────────────────────
  static final List<SpecialOfferItem> specialOffers = [
    SpecialOfferItem(
      id: 'starter_pack',
      label: 'Starter Pack',
      description: '2000 Coins + 5 Hints + 5 Undos + 3 Extra Tubes',
      price: '\$1.99',
      productId: 'com.yourapp.starter_pack',
      icon: '🎁',
      coins: 2000,
      hints: 5,
      undos: 5,
      extraTubes: 3,
      isOneTime: true,
    ),
    SpecialOfferItem(
      id: 'remove_ads',
      label: 'Remove Ads',
      description: 'Remove all interstitial ads forever',
      price: '\$2.99',
      productId: 'com.yourapp.remove_ads',
      icon: '🚫',
      coins: 0,
      hints: 0,
      undos: 0,
      extraTubes: 0,
      isOneTime: false,
    ),
  ];
}