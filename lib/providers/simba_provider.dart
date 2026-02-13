import 'package:flutter/foundation.dart';
import '../models/api_product.dart';
import '../models/api_card.dart';
import '../models/api_event.dart';
import '../models/api_ticket.dart';
import '../services/simba_api_service.dart';

class SimbaProvider with ChangeNotifier {
  // Products state
  List<ApiProduct> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  // Events state
  List<ApiEvent> _events = [];
  bool _isLoadingEvents = false;
  String? _eventsError;

  // Ticket types state
  List<TicketType> _ticketTypes = [];
  bool _isLoadingTicketTypes = false;
  String? _ticketTypesError;

  // Card state
  String? _cardNumber;
  CardBalanceResponse? _lastBalanceResponse;
  CardTopUpResponse? _lastTopUpResponse;

  // Transaction responses
  ProductPurchaseResponse? _lastProductPurchase;
  TicketPurchaseResponse? _lastTicketPurchase;

  // Getters
  List<ApiProduct> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;

  List<ApiEvent> get events => _events;
  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventsError => _eventsError;

  List<TicketType> get ticketTypes => _ticketTypes;
  bool get isLoadingTicketTypes => _isLoadingTicketTypes;
  String? get ticketTypesError => _ticketTypesError;

  String? get cardNumber => _cardNumber;
  CardBalanceResponse? get lastBalanceResponse => _lastBalanceResponse;
  CardTopUpResponse? get lastTopUpResponse => _lastTopUpResponse;
  ProductPurchaseResponse? get lastProductPurchase => _lastProductPurchase;
  TicketPurchaseResponse? get lastTicketPurchase => _lastTicketPurchase;

  // Fetch products on sale
  Future<void> fetchProductsOnSale({int limit = 50}) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      print('DEBUG Provider: Fetching products...');
      _products = await SimbaApiService.getProductsOnSale(limit: limit);
      print('DEBUG Provider: Successfully fetched ${_products.length} products');
      _isLoadingProducts = false;
      _productsError = null;
      notifyListeners();
    } catch (e) {
      print('DEBUG Provider: Error fetching products: $e');
      _isLoadingProducts = false;
      _productsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Fetch active events
  Future<void> fetchActiveEvents({int limit = 50}) async {
    _isLoadingEvents = true;
    _eventsError = null;
    notifyListeners();

    try {
      print('DEBUG Provider: Fetching events...');
      _events = await SimbaApiService.getActiveEvents(limit: limit);
      print('DEBUG Provider: Successfully fetched ${_events.length} events');
      _isLoadingEvents = false;
      _eventsError = null;
      notifyListeners();
    } catch (e) {
      print('DEBUG Provider: Error fetching events: $e');
      _isLoadingEvents = false;
      _eventsError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Fetch ticket types for an event
  Future<void> fetchTicketTypes(int eventId) async {
    _isLoadingTicketTypes = true;
    _ticketTypesError = null;
    notifyListeners();

    try {
      final response = await SimbaApiService.getEventTicketTypes(eventId);
      _ticketTypes = response['ticket_types'] as List<TicketType>;
      _isLoadingTicketTypes = false;
      _ticketTypesError = null;
      notifyListeners();
    } catch (e) {
      _isLoadingTicketTypes = false;
      _ticketTypesError = e.toString();
      _ticketTypes = [];
      notifyListeners();
    }
  }

  // Set card number
  void setCardNumber(String cardNumber) {
    _cardNumber = cardNumber;
    notifyListeners();
  }

  // Get card balance
  Future<bool> getCardBalance(String cardNumber) async {
    _cardNumber = cardNumber;
    final request = CardBalanceRequest(cardNumber: cardNumber);

    try {
      _lastBalanceResponse = await SimbaApiService.getCardBalance(request);
      notifyListeners();
      return _lastBalanceResponse!.success;
    } catch (e) {
      _lastBalanceResponse = CardBalanceResponse(
        success: false,
        message: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Top up card
  Future<bool> topUpCard({
    required String cardNumber,
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    _cardNumber = cardNumber;
    final request = CardTopUpRequest(
      cardNumber: cardNumber,
      amount: amount,
      paymentMethod: paymentMethod,
      description: description,
    );

    try {
      _lastTopUpResponse = await SimbaApiService.topUpCard(request);
      notifyListeners();
      return _lastTopUpResponse!.success;
    } catch (e) {
      _lastTopUpResponse = CardTopUpResponse(
        success: false,
        message: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Purchase product
  Future<bool> purchaseProduct({
    required int productId,
    required int quantity,
    String? cardNumber,
    int? userId,
    required String paymentMethod,
  }) async {
    final request = ProductPurchaseRequest(
      productId: productId,
      quantity: quantity,
      cardNumber: cardNumber,
      userId: userId,
      paymentMethod: paymentMethod,
    );

    try {
      _lastProductPurchase = await SimbaApiService.purchaseProduct(request);

      // Update card balance if available
      if (_lastProductPurchase!.success && _lastProductPurchase!.balance != null) {
        _lastBalanceResponse = CardBalanceResponse(
          success: true,
          balance: _lastProductPurchase!.balance,
        );
      }

      notifyListeners();
      return _lastProductPurchase!.success;
    } catch (e) {
      _lastProductPurchase = ProductPurchaseResponse(
        success: false,
        message: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Purchase ticket
  Future<bool> purchaseTicket({
    required int eventId,
    required int ticketTypeId,
    String? cardNumber,
    int? userId,
    required String paymentMethod,
  }) async {
    final request = TicketPurchaseRequest(
      eventId: eventId,
      ticketTypeId: ticketTypeId,
      cardNumber: cardNumber,
      userId: userId,
      paymentMethod: paymentMethod,
    );

    try {
      _lastTicketPurchase = await SimbaApiService.purchaseTicket(request);

      // Update card balance if available
      if (_lastTicketPurchase!.success && _lastTicketPurchase!.balance != null) {
        _lastBalanceResponse = CardBalanceResponse(
          success: true,
          balance: _lastTicketPurchase!.balance,
        );
      }

      notifyListeners();
      return _lastTicketPurchase!.success;
    } catch (e) {
      _lastTicketPurchase = TicketPurchaseResponse(
        success: false,
        message: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Clear card info
  void clearCardInfo() {
    _cardNumber = null;
    _lastBalanceResponse = null;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _products = [];
    _events = [];
    _ticketTypes = [];
    _cardNumber = null;
    _lastBalanceResponse = null;
    _lastTopUpResponse = null;
    _lastProductPurchase = null;
    _lastTicketPurchase = null;
    _productsError = null;
    _eventsError = null;
    _ticketTypesError = null;
    notifyListeners();
  }
}
