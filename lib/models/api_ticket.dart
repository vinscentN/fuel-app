import 'api_product.dart';

class TicketType {
  final int id;
  final String name;
  final String defaultPrice;
  final Currency? currency;

  TicketType({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.currency,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'],
      name: json['name'],
      defaultPrice: json['default_price'].toString(),
      currency: json['currency'] != null
          ? Currency.fromJson(json['currency'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_price': defaultPrice,
      'currency': currency?.toJson(),
    };
  }

  double get priceValue => double.tryParse(defaultPrice) ?? 0.0;
}

// Ticket purchase request
class TicketPurchaseRequest {
  final int eventId;
  final int ticketTypeId;
  final String? cardNumber;
  final int? userId;
  final String paymentMethod; // 'card', 'cash', 'mobile'

  TicketPurchaseRequest({
    required this.eventId,
    required this.ticketTypeId,
    this.cardNumber,
    this.userId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'event_id': eventId,
      'ticket_type_id': ticketTypeId,
      'payment_method': paymentMethod,
    };

    if (cardNumber != null) {
      json['card_number'] = cardNumber;
    }
    if (userId != null) {
      json['user_id'] = userId;
    }

    return json;
  }
}

// Ticket purchase response
class TicketPurchaseResponse {
  final bool success;
  final String? message;
  final Ticket? ticket;
  final TicketTransaction? transaction;
  final String? balance;

  TicketPurchaseResponse({
    required this.success,
    this.message,
    this.ticket,
    this.transaction,
    this.balance,
  });

  factory TicketPurchaseResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      final data = json['data'];
      return TicketPurchaseResponse(
        success: true,
        ticket: data['ticket'] != null
            ? Ticket.fromJson(data['ticket'])
            : null,
        transaction: data['transaction'] != null
            ? TicketTransaction.fromJson(data['transaction'])
            : null,
        balance: data['balance']?.toString(),
      );
    } else {
      return TicketPurchaseResponse(
        success: false,
        message: json['message'] ?? 'Failed to purchase ticket',
      );
    }
  }
}

class Ticket {
  final int id;
  final String ticketNumber;
  final int eventId;
  final int ticketTypeId;
  final String ticketType;
  final String price;
  final String paymentMethod;
  final String status;
  final String purchasedAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.eventId,
    required this.ticketTypeId,
    required this.ticketType,
    required this.price,
    required this.paymentMethod,
    required this.status,
    required this.purchasedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketNumber: json['ticket_number'],
      eventId: json['event_id'],
      ticketTypeId: json['ticket_type_id'],
      ticketType: json['ticket_type'],
      price: json['price'].toString(),
      paymentMethod: json['payment_method'],
      status: json['status'],
      purchasedAt: json['purchased_at'],
    );
  }

  double get priceValue => double.tryParse(price) ?? 0.0;
}

class TicketTransaction {
  final int id;
  final String transactionNumber;
  final String type;
  final String amount;
  final String? balanceBefore;
  final String? balanceAfter;
  final String status;

  TicketTransaction({
    required this.id,
    required this.transactionNumber,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    required this.status,
  });

  factory TicketTransaction.fromJson(Map<String, dynamic> json) {
    return TicketTransaction(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      type: json['type'],
      amount: json['amount'].toString(),
      balanceBefore: json['balance_before']?.toString(),
      balanceAfter: json['balance_after']?.toString(),
      status: json['status'],
    );
  }
}
