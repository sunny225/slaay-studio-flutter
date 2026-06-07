import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile/models/order.dart';
import 'api_client.dart';

class OrderService {
  static const String _localOrdersKey = 'local_orders_history';

  // Retrieve user orders history
  Future<List<OrderModel>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        final response = await ApiClient.get('/orders');
        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            final List<dynamic> data = body['data'];
            return data.map((item) => OrderModel.fromJson(item)).toList();
          }
        }
      } catch (_) {
        // Fallback to local storage if API is offline/network error
      }
    }

    final String? localOrdersStr = prefs.getString(_localOrdersKey);
    if (localOrdersStr != null) {
      final List<dynamic> decoded = jsonDecode(localOrdersStr);
      return decoded.map((item) => OrderModel.fromJson(item)).toList();
    }
    return [];
  }

  // Place a new order
  Future<OrderModel> placeOrder(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        // Map paymentMethod to lowercase cod or razorpay
        String paymentMethodApi = 'cod';
        if (order.paymentMethod.toLowerCase() == 'razorpay' || 
            order.paymentMethod.toLowerCase() == 'upi' || 
            order.paymentMethod.toLowerCase() == 'card') {
          paymentMethodApi = 'razorpay';
        }

        // Map items to backend variation expectations
        final List<Map<String, dynamic>> apiItems = order.items.map((item) {
          return {
            'product': item.product.id,
            'quantity': item.quantity,
            'price': item.product.price,
            'variant': item.size,
            'sku': 'SIZE_${item.size}',
          };
        }).toList();

        // Map address
        final Map<String, dynamic> apiShippingAddress = {
          'fullName': order.address.fullName,
          'phone': order.address.phoneNumber,
          'street': '${order.address.flatHouseNo}, ${order.address.areaStreet}',
          'city': order.address.city,
          'state': order.address.state,
          'pincode': order.address.pincode,
          'country': 'India',
        };

        final payload = {
          'shippingAddress': apiShippingAddress,
          'items': apiItems,
          'paymentMethod': paymentMethodApi,
          if (order.couponCode != null) 'couponCode': order.couponCode,
        };

        final response = await ApiClient.post('/orders', payload);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            return OrderModel.fromJson(body['data']);
          }
        }

        // Server returned an error status (e.g., 401 Unauthorized, 400 Bad Request, etc.)
        final Map<String, dynamic> body = jsonDecode(response.body);
        final String errorMsg = body['message'] ?? 'Server error (${response.statusCode})';
        throw ApiException(errorMsg);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to connect to the server. Please check your network and try again.');
      }
    }

    // Persist locally in SharedPreferences for mockup tracking (Demo / Mock Mode)
    final List<OrderModel> currentOrders = await getOrders();
    
    // Add the new order to local listing
    currentOrders.insert(0, order);
    
    final List<Map<String, dynamic>> jsonList = currentOrders.map((o) => o.toJson()).toList();
    await prefs.setString(_localOrdersKey, jsonEncode(jsonList));
    
    return order;
  }

  // Create Razorpay payment order
  Future<String> createPaymentOrder(String orderId) async {
    try {
      final response = await ApiClient.post('/payments/create-order', {
        'orderId': orderId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data']['razorpayOrderId'];
        }
      }
      final Map<String, dynamic> body = jsonDecode(response.body);
      final String errorMsg = body['message'] ?? 'Failed to create payment order';
      throw ApiException(errorMsg);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error creating payment order. Please try again.');
    }
  }

  // Verify payment
  Future<bool> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await ApiClient.post('/payments/verify', {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return body['success'] == true;
      }
      final Map<String, dynamic> body = jsonDecode(response.body);
      final String errorMsg = body['message'] ?? 'Payment verification failed';
      throw ApiException(errorMsg);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error verifying payment. Please try again.');
    }
  }

  // Update order status (for mockup tracking step demonstration)
  Future<void> updateLocalOrderStatus(String orderId, OrderStatus newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final List<OrderModel> currentOrders = await getOrders();
    
    for (int i = 0; i < currentOrders.length; i++) {
      if (currentOrders[i].id == orderId) {
        final updatedOrder = OrderModel(
          id: currentOrders[i].id,
          items: currentOrders[i].items,
          totalAmount: currentOrders[i].totalAmount,
          date: currentOrders[i].date,
          status: newStatus,
          address: currentOrders[i].address,
          paymentMethod: currentOrders[i].paymentMethod,
        );
        currentOrders[i] = updatedOrder;
        break;
      }
    }
    
    final List<Map<String, dynamic>> jsonList = currentOrders.map((o) => o.toJson()).toList();
    await prefs.setString(_localOrdersKey, jsonEncode(jsonList));
  }
}
