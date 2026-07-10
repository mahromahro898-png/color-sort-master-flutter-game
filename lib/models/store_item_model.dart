/// ══════════════════════════════════════════════════════════
///  store_item_model.dart
///  Modelo de Itens da Loja - Uso de herança e polimorfismo para estruturar os produtos da loja virtual
/// ══════════════════════════════════════════════════════════

enum BoosterType { hint, undo, extraTube, heartRefill }

// ── Base (Classe abstrata garantindo o contrato comum entre produtos) ────────────────────────────────────────────────────
abstract class StoreItem {
  final String id;
  final String label;
  final String icon;

  const StoreItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

// ── Coin Pack (Integração com In-App Purchases / Hard Currency) ───────────────────────────────────────────────
class CoinPackItem extends StoreItem {
  final int coins;
  final String price;
  final String productId;
  final bool isBestValue;
  final bool isPopular;

  const CoinPackItem({
    required super.id,
    required this.coins,
    required this.price,
    required this.productId,
    required super.label,
    required super.icon,
    this.isBestValue = false,
    this.isPopular = false,
  });
}

// ── Booster (Itens consumíveis adquiridos com moeda virtual / Soft Currency) ─────────────────────────────────────────────────
class BoosterItem extends StoreItem {
  final BoosterType type;
  final int amount;
  final int coinPrice;
  final bool isBestValue;

  const BoosterItem({
    required super.id,
    required this.type,
    required this.amount,
    required this.coinPrice,
    required super.label,
    required super.icon,
    this.isBestValue = false,
  });
}

// ── Special Offer (Bundles e Promoções Especiais) ────────────────────────────────────────────
class SpecialOfferItem extends StoreItem {
  final String description;
  final String price;
  final String productId;
  final int coins;
  final int hints;
  final int undos;
  final int extraTubes;
  final bool isOneTime; // Controle de compra única (Non-consumable / One-time purchase)

  const SpecialOfferItem({
    required super.id,
    required super.label,
    required this.description,
    required this.price,
    required this.productId,
    required super.icon,
    required this.coins,
    required this.hints,
    required this.undos,
    required this.extraTubes,
    required this.isOneTime,
  });
}