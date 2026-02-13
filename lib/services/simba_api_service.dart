import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_product.dart';
import '../models/api_card.dart';
import '../models/api_event.dart';
import '../models/api_ticket.dart';

class SimbaApiService {
  // TODO: Update this with your actual backend URL
  static const String baseUrl = 'https://clubmate-sandbox.poscloud.co.zw/api/v1';

  // Test connectivity
  static Future<bool> testConnection() async {
    try {
      print('DEBUG API: Testing connection to $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/products/on-sale'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      print('DEBUG API: Connection test result: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG API: Connection test failed: $e');
      return false;
    }
  }

  // 1. GET /products/on-sale
  static Future<List<ApiProduct>> getProductsOnSale({int limit = 50}) async {
    try {
      final url = '$baseUrl/products/on-sale?limit=$limit';
      print('DEBUG API: Calling products on-sale endpoint: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        print('DEBUG API: Parsed JSON response: $jsonResponse');

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final List<dynamic> productsJson = jsonResponse['data'];
          print('DEBUG API: Found ${productsJson.length} products');

          try {
            return productsJson
                .map((json) => ApiProduct.fromJson(json as Map<String, dynamic>))
                .toList();
          } catch (parseError) {
            print('DEBUG API: Error parsing product: $parseError');
            print('DEBUG API: Problematic product data: $productsJson');
            throw Exception('Failed to parse products: $parseError');
          }
        } else {
          throw Exception('Failed to fetch products: Invalid response format - status: ${jsonResponse['status']}, has data: ${jsonResponse['data'] != null}');
        }
      } else {
        throw Exception(
            'Failed to fetch products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Error fetching products: $e');
      rethrow;
    }
  }

  // 2. POST /products/purchase
  static Future<ProductPurchaseResponse> purchaseProduct(
      ProductPurchaseRequest request) async {
    try {
      final payload = request.toJson();
      print('DEBUG API: Calling product purchase endpoint');
      print('DEBUG API: URL: $baseUrl/products/purchase');
      print('DEBUG API: Request body: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/products/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Purchase response status: ${response.statusCode}');
      print('DEBUG API: Purchase response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductPurchaseResponse.fromJson(jsonResponse);
      } else {
        return ProductPurchaseResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Purchase failed',
        );
      }
    } catch (e) {
      print('DEBUG API: Error purchasing product: $e');
      return ProductPurchaseResponse(
        success: false,
        message: 'Error purchasing product: $e',
      );
    }
  }

  // 3. POST /cards/balance
  static Future<CardBalanceResponse> getCardBalance(
      CardBalanceRequest request) async {
    try {
      final payload = request.toJson();
      print('DEBUG API: Calling card balance endpoint');
      print('DEBUG API: URL: $baseUrl/cards/balance');
      print('DEBUG API: Request body: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/cards/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Balance response status: ${response.statusCode}');
      print('DEBUG API: Balance response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      return CardBalanceResponse.fromJson(jsonResponse);
    } catch (e) {
      print('DEBUG API: Error getting card balance: $e');
      return CardBalanceResponse(
        success: false,
        message: 'Error getting card balance: $e',
      );
    }
  }

  // 4. POST /cards/top-up
  static Future<CardTopUpResponse> topUpCard(CardTopUpRequest request) async {
    try {
      final payload = request.toJson();
      print('DEBUG API: Calling card top-up endpoint');
      print('DEBUG API: URL: $baseUrl/cards/top-up');
      print('DEBUG API: Request body: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/cards/top-up'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Top-up response status: ${response.statusCode}');
      print('DEBUG API: Top-up response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      return CardTopUpResponse.fromJson(jsonResponse);
    } catch (e) {
      print('DEBUG API: Error topping up card: $e');
      return CardTopUpResponse(
        success: false,
        message: 'Error topping up card: $e',
      );
    }
  }

  // 5. GET /events/active
  static Future<List<ApiEvent>> getActiveEvents({int limit = 50}) async {
    try {
      final url = '$baseUrl/events/active?limit=$limit';
      print('DEBUG API: Calling active events endpoint: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        print('DEBUG API: Parsed JSON response: $jsonResponse');

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final List<dynamic> eventsJson = jsonResponse['data'];
          print('DEBUG API: Found ${eventsJson.length} events');

          try {
            return eventsJson
                .map((json) => ApiEvent.fromJson(json as Map<String, dynamic>))
                .toList();
          } catch (parseError) {
            print('DEBUG API: Error parsing event: $parseError');
            print('DEBUG API: Problematic event data: $eventsJson');
            throw Exception('Failed to parse events: $parseError');
          }
        } else {
          throw Exception('Failed to fetch events: Invalid response format - status: ${jsonResponse['status']}, has data: ${jsonResponse['data'] != null}');
        }
      } else {
        throw Exception(
            'Failed to fetch events: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Error fetching events: $e');
      rethrow;
    }
  }

  // 6. GET /events/{eventId}/ticket-types
  static Future<Map<String, dynamic>> getEventTicketTypes(int eventId) async {
    try {
      final url = '$baseUrl/events/$eventId/ticket-types';
      print('DEBUG API: Calling event ticket types endpoint: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final List<dynamic> ticketTypesJson = data['ticket_types'] ?? [];

          return {
            'event': data['event'],
            'ticket_types': ticketTypesJson
                .map((json) => TicketType.fromJson(json))
                .toList(),
          };
        } else {
          throw Exception('Failed to fetch ticket types: Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to fetch ticket types: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Error fetching ticket types: $e');
      throw Exception('Error fetching ticket types: $e');
    }
  }

  // 7. POST /tickets/purchase
  static Future<TicketPurchaseResponse> purchaseTicket(
      TicketPurchaseRequest request) async {
    try {
      final payload = request.toJson();
      print('DEBUG API: Calling ticket purchase endpoint');
      print('DEBUG API: URL: $baseUrl/tickets/purchase');
      print('DEBUG API: Request body: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/tickets/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      print('DEBUG API: Ticket purchase response status: ${response.statusCode}');
      print('DEBUG API: Ticket purchase response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      return TicketPurchaseResponse.fromJson(jsonResponse);
    } catch (e) {
      print('DEBUG API: Error purchasing ticket: $e');
      return TicketPurchaseResponse(
        success: false,
        message: 'Error purchasing ticket: $e',
      );
    }
  }
}
