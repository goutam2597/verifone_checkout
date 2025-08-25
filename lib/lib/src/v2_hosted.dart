import 'package:flutter/material.dart';
import 'checkout_webview.dart';
import 'v2_models.dart';

/// Open a Verifone 2Checkout hosted buy-link / ConvertPlus URL with no secrets.
class V2HostedCheckout {
  static Future<V2HostedResult> open({
    required BuildContext context,
    required String checkoutUrl,  // Hosted URL from your dashboard or V2BuyLink.build()
    required String returnUrl,    // myapp://payment-return (recommended) or https://...
    String? reference,            // your order id to echo back
    String? appBarTitle,
  }) async {
    Uri? returned;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutWebView(
          checkoutUrl: checkoutUrl,
          returnUrl: returnUrl,
          onReturn: (uri) => returned = uri,
          appBarTitle: appBarTitle ?? '2Checkout',
        ),
      ),
    );

    final qp = returned?.queryParameters ?? {};
    final status = _normalize(
      qp['status'] ??
          qp['result'] ??
          qp['response'] ??
          qp['order_status'] ??
          'PENDING',
    );

    return V2HostedResult(
      reference: reference ?? (qp['order_reference'] ?? ''),
      status: status,
      raw: {
        'returnUri': returned?.toString(),
        'returnParams': qp,
      },
    );
  }

  static String _normalize(String s) {
    final t = s.toUpperCase();
    if (['SUCCESS', 'PAID', 'APPROVED', 'AUTHORIZED', 'AUTHORISED'].contains(t)) return 'SUCCESS';
    if (['FAILED', 'DECLINED', 'ERROR'].contains(t)) return 'FAILED';
    if (['CANCELLED', 'CANCELED', 'VOID'].contains(t)) return 'CANCELED';
    return 'PENDING';
  }
}
