/// Tiny helper to build a ConvertPlus / hosted buy-link **without** server/secrets.
/// Docs show patterns like:
///   https://sandbox.2checkout.com/checkout/purchase?sid=YOUR_SID&mode=2CO&li_0_type=product...
class V2BuyLink {
  /// Build a hosted URL from your seller id (sid / merchant code) and line items.
  ///
  /// Example:
  ///   final url = V2BuyLink.build(
  ///     sandbox: true,
  ///     sid: '255666497484',
  ///     currency: 'USD',
  ///     returnUrl: 'myapp://payment-return',
  ///     items: [
  ///       V2Item(name: 'Pro Plan', price: 10.00),
  ///     ],
  ///   );
  static String build({
    required bool sandbox,
    required String sid,
    required List<V2Item> items,
    String currency = 'USD',
    String mode = '2CO', // standard hosted mode
    String? returnUrl,   // if dashboard allows, set your return URL here
    Map<String, String> extra = const {}, // add any additional CP params
  }) {
    final host = sandbox
        ? 'https://sandbox.2checkout.com/checkout/purchase'
        : 'https://secure.2checkout.com/checkout/purchase';

    final params = <String, String>{
      'sid': sid,
      'mode': mode,
      'currency_code': currency,
      if (returnUrl != null) 'return_url': returnUrl,
      ...extra,
    };

    // Add items as li_0_, li_1_, ...
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      params['li_${i}_type']  = 'product';
      params['li_${i}_name']  = it.name;
      params['li_${i}_price'] = it.price.toStringAsFixed(2);
      if (it.quantity != null) params['li_${i}_quantity'] = '${it.quantity}';
      if (it.productId != null) params['li_${i}_product_id'] = it.productId!;
    }

    final query = params.entries.map((e) =>
    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}'
    ).join('&');

    return '$host?$query';
  }
}

/// Represents a line item for the buy-link.
class V2Item {
  final String name;
  final double price;
  final int? quantity;
  final String? productId;

  const V2Item({
    required this.name,
    required this.price,
    this.quantity,
    this.productId,
  });
}
