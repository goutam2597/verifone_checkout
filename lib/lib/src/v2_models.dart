/// Result of a Verifone 2Checkout hosted checkout flow.
class V2PaymentResult {
  /// Your order reference or merchant reference (if you pass one around).
  final String reference;

  /// Simplified status label (SUCCESS / PENDING / FAILED / CANCELED).
  final String status;

  /// Raw payloads captured during the flow (e.g., return URI, server verify).
  final Map<String, dynamic> raw;

  const V2PaymentResult({
    required this.reference,
    required this.status,
    required this.raw,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

/// Exception thrown by Verifone 2Checkout wrapper.
class V2CheckoutException implements Exception {
  final String message;
  final Object? cause;
  V2CheckoutException(this.message, [this.cause]);
  @override
  String toString() => 'V2CheckoutException: $message';
}
