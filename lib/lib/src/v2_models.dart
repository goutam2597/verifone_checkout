/// Result from the hosted checkout flow.
class V2HostedResult {
  final String reference;         // your order ref (optional)
  final String status;            // SUCCESS | PENDING | FAILED | CANCELED
  final Map<String, dynamic> raw; // return params / uri, etc.

  const V2HostedResult({
    required this.reference,
    required this.status,
    required this.raw,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

class V2HostedException implements Exception {
  final String message;
  final Object? cause;
  V2HostedException(this.message, [this.cause]);
  @override
  String toString() => 'V2HostedException: $message';
}
