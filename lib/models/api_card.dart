// Card balance request
class CardBalanceRequest {
  final String cardNumber;

  CardBalanceRequest({
    required this.cardNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_number': cardNumber,
    };
  }
}

// Card balance response
class CardBalanceResponse {
  final bool success;
  final String? message;
  final String? cardNumber;
  final String? status;
  final String? expiryDate;
  final String? currency;
  final String? balance;

  CardBalanceResponse({
    required this.success,
    this.message,
    this.cardNumber,
    this.status,
    this.expiryDate,
    this.currency,
    this.balance,
  });

  factory CardBalanceResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      final data = json['data'];
      return CardBalanceResponse(
        success: true,
        cardNumber: data['card_number'],
        status: data['status'],
        expiryDate: data['expiry_date'],
        currency: data['currency'],
        balance: data['balance']?.toString(),
      );
    } else {
      return CardBalanceResponse(
        success: false,
        message: json['message'] ?? 'Failed to get card balance',
      );
    }
  }

  double get balanceValue => double.tryParse(balance ?? '0') ?? 0.0;
}

// Card top-up request
class CardTopUpRequest {
  final String cardNumber;
  final double amount;
  final String paymentMethod; // 'mobile', 'cash', etc.
  final String? description;

  CardTopUpRequest({
    required this.cardNumber,
    required this.amount,
    required this.paymentMethod,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'card_number': cardNumber,
      'amount': amount,
      'payment_method': paymentMethod,
    };

    if (description != null) {
      json['description'] = description;
    }

    return json;
  }
}

// Card top-up response
class CardTopUpResponse {
  final bool success;
  final String? message;
  final TopUpTransaction? transaction;
  final String? balance;

  CardTopUpResponse({
    required this.success,
    this.message,
    this.transaction,
    this.balance,
  });

  factory CardTopUpResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      final data = json['data'];
      return CardTopUpResponse(
        success: true,
        transaction: data['transaction'] != null
            ? TopUpTransaction.fromJson(data['transaction'])
            : null,
        balance: data['balance']?.toString(),
      );
    } else {
      return CardTopUpResponse(
        success: false,
        message: json['message'] ?? 'Failed to top up card',
      );
    }
  }

  double get balanceValue => double.tryParse(balance ?? '0') ?? 0.0;
}

class TopUpTransaction {
  final int id;
  final String transactionNumber;
  final int? membershipCardId;
  final int? userId;
  final String type;
  final String amount;
  final int currencyId;
  final String balanceBefore;
  final String balanceAfter;
  final String status;

  TopUpTransaction({
    required this.id,
    required this.transactionNumber,
    this.membershipCardId,
    this.userId,
    required this.type,
    required this.amount,
    required this.currencyId,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
  });

  factory TopUpTransaction.fromJson(Map<String, dynamic> json) {
    return TopUpTransaction(
      id: json['id'],
      transactionNumber: json['transaction_number'],
      membershipCardId: json['membership_card_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: json['amount'].toString(),
      currencyId: json['currency_id'],
      balanceBefore: json['balance_before'].toString(),
      balanceAfter: json['balance_after'].toString(),
      status: json['status'],
    );
  }
}
