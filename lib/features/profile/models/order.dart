import '../../cart/models/cart_item.dart';

enum OrderStatus {
  placed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled
}

class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String flatHouseNo;
  final String areaStreet;
  final String city;
  final String state;
  final String pincode;

  ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.flatHouseNo,
    required this.areaStreet,
    required this.city,
    required this.state,
    required this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'flatHouseNo': flatHouseNo,
      'areaStreet': areaStreet,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    final streetStr = json['street'] ?? json['addressLine1'] ?? '';
    String flat = streetStr;
    String area = '';
    final commaIdx = streetStr.indexOf(',');
    if (commaIdx != -1) {
      flat = streetStr.substring(0, commaIdx).trim();
      area = streetStr.substring(commaIdx + 1).trim();
    }
    return ShippingAddress(
      fullName: json['fullName'] ?? json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      flatHouseNo: json['flatHouseNo'] ?? (flat.isNotEmpty ? flat : ''),
      areaStreet: json['areaStreet'] ?? area,
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? json['postalCode'] ?? '',
    );
  }
  
  String get fullAddressString => "$flatHouseNo, ${areaStreet.isNotEmpty ? '$areaStreet, ' : ''}$city, $state - $pincode";
}

class OrderModel {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final OrderStatus status;
  final ShippingAddress address;
  final String paymentMethod;
  final String? couponCode;

  OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.status,
    required this.address,
    required this.paymentMethod,
    this.couponCode,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderStatus getStatus(String statusStr) {
      switch (statusStr.toLowerCase()) {
        case 'placed':
        case 'pending':
          return OrderStatus.placed;
        case 'packed':
        case 'processing':
          return OrderStatus.packed;
        case 'shipped':
          return OrderStatus.shipped;
        case 'outfordelivery':
        case 'out_for_delivery':
          return OrderStatus.outForDelivery;
        case 'delivered':
          return OrderStatus.delivered;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.placed;
      }
    }

    final rawItems = json['items'] as List? ?? [];
    final List<CartItem> parsedItems = rawItems.map((i) {
      if (i is Map<String, dynamic>) {
        return CartItem.fromJson(i);
      }
      return CartItem.fromJson({});
    }).toList();

    return OrderModel(
      id: json['orderNumber'] ?? json['_id'] ?? json['id'] ?? '',
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: getStatus(json['orderStatus'] ?? json['status'] ?? 'placed'),
      address: json['shippingAddress'] != null 
          ? ShippingAddress.fromJson(json['shippingAddress']) 
          : (json['address'] != null 
              ? ShippingAddress.fromJson(json['address'])
              : ShippingAddress(fullName: '', phoneNumber: '', flatHouseNo: '', areaStreet: '', city: '', state: '', pincode: '')),
      paymentMethod: json['paymentMethod'] ?? 'UPI',
      couponCode: json['couponCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'status': status.name,
      'address': address.toJson(),
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
    };
  }
}
