import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StoreManager extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Mapa reativo para atualizar os preços na interface (UI) em tempo real
  Map<String, String> livePrices = {};
  List<ProductDetails> _products = [];
  bool isAvailable = false;

  // ⚠️ IMPORTANTE: Estes IDs devem corresponder estritamente aos configurados na Google Play Console e na store_screen
  final Set<String> _productIds = {
    'com.game.pack.1000', 'com.game.pack.2000', 'com.game.pack.4000', 'com.game.pack.8000',
    'com.game.coins.1000', 'com.game.coins.2000', 'com.game.coins.5000', 'com.game.coins.10000',
    'com.game.coins.25000', 'com.game.coins.50000'
  };

  StoreManager() {
    _initializeIAP();
  }

  void _initializeIAP() {
    // Listener para o fluxo de respostas da Google Play (Sucesso/Falha da transação)
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('Error listening to purchases: $error');
    });

    // Busca inicial (Fetch) de produtos e preços assim que a loja é instanciada
    loadProducts();
  }

  Future<void> loadProducts() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      debugPrint('Store not available');
      return;
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint('Error fetching products: ${response.error!.message}');
      return;
    }

    _products = response.productDetails;

    // Extração e mapeamento do preço localizado fornecido pela Google (ex: R$ 10,90 ou $2.99)
    for (var product in _products) {
      livePrices[product.id] = product.price;
    }

    // Notifica os listeners (StoreScreen) para reconstruir a UI com os preços atualizados
    notifyListeners();
  }

  /// Trigger de compra - Invocado quando o usuário interage com o botão de checkout
  void buyProduct(String productId) {
    // Busca o produto correspondente no catálogo (Cache) retornado pela Google Play
    final ProductDetails? product = _products.cast<ProductDetails?>().firstWhere(
          (p) => p?.id == productId,
      orElse: () => null,
    );

    if (product != null) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      // Utilização de 'buyConsumable' para itens que podem ser comprados repetidamente (Hard/Soft Currency)
      _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      debugPrint("Product $productId not found in Google Play store");
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase is pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase failed: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          // ✅ Transação concluída com sucesso! Ponto de injeção para creditar as moedas ou pacotes ao jogador
          _deliverProduct(purchaseDetails.productID);
        }

        // Confirmação obrigatória (Acknowledge) para a Google Play para finalizar a compra e evitar reembolsos automáticos
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _deliverProduct(String productId) {
    debugPrint('Delivering item for ID: $productId');

    // 🪙 Seção de Moedas (Hard Currency)
    if (productId == 'com.game.coins.1000') {
      // Injetar 1000 moedas no saldo do jogador
    } else if (productId == 'com.game.coins.2000') {
      // Injetar 2000 moedas no saldo do jogador
    } else if (productId == 'com.game.coins.5000') {
      // Injetar 5000 moedas no saldo do jogador
    } else if (productId == 'com.game.coins.10000') {
      // Injetar 10000 moedas no saldo do jogador
    } else if (productId == 'com.game.coins.25000') {
      // Injetar 25000 moedas no saldo do jogador
    } else if (productId == 'com.game.coins.50000') {
      // Injetar 50000 moedas no saldo do jogador
    }

    // ✨ Seção de Pacotes Especiais (Bundles)
    else if (productId == 'com.game.pack.1000') {
      // Creditar os itens do pacote de desconto básico ao jogador
    } else if (productId == 'com.game.pack.2000') {
      // Creditar os itens do pacote de 2000 ao jogador
    } else if (productId == 'com.game.pack.4000') {
      // Creditar os itens do pacote de 4000 ao jogador
    } else if (productId == 'com.game.pack.8000') {
      // Creditar os itens do pacote de 8000 ao jogador
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}