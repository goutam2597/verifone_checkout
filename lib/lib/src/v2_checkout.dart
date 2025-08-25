import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:verifone2_checkout_flutter/lib/src/v2_env.dart';

import 'checkout_webview.dart';
import 'v2_config.dart';
import 'v2_models.dart';

/// Verifone 2Checkout wrapper (hosted checkout).
///
/// 2Checkout flows are generally:
///  - Your backend creates a payment session or buy-link (server-side, with secret).
///  - You open the hosted checkout URL here.
///  - Gateway redirects back to your app/site (return URL).
///  - (Optional) You verify/order-status via *your backend*.
///
/// This client provides:
///  - [openHostedCheckout]: open an existing hosted URL (no backend needed).
///  - [startViaServer]: ask your backend for a hosted URL, then open it.
class V2Checkout {
  /// Open a given hosted checkout URL and intercept [returnUrl].
  static Future<V2PaymentResult> openHostedCheckout({
    required BuildContext context,
    required V2Config config,
    required String hostedCheckoutUrl,
    required String returnUrl,
    String? reference,      // your own order/reference id (for echo)
    String? appBarTitle,
  }) async {
    Uri? returned;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutWebView(
          checkoutUrl: hostedCheckoutUrl,
          returnUrl: returnUrl,
          onReturn: (uri) => returned = uri,
          appBarTitle: appBarTitle ?? '2Checkout',
        ),
      ),
    );

    // Basic status normalization from common query params:
    final params = returned?.queryParameters ?? {};
    final status = _normalizeStatus(
      params['status'] ??
          params['result'] ??
          params['code'] ??
          params['order_status'] ??
          'PENDING',
    );

    if (config.enableLogs) {
      // ignore: avoid_print
      print('[V2] Return URI: ${returned ?? '-'}  → status=$status');
    }

    return V2PaymentResult(
      reference: reference ?? (params['order_reference'] ?? ''),
      status: status,
      raw: {
        'flowId': config.flowId,
        'environment': config.environment.label,
        'merchantCode': config.merchantCode,
        'hostedCheckoutUrl': hostedCheckoutUrl,
        'returnUri': returned?.toString(),
        'returnParams': params,
      },
    );
  }

  /// Ask your backend to create a session/buy-link, then open it.
  /// Your backend response should be like:
  ///   { "checkoutUrl": "...", "reference": "ORD_12345" }
  static Future<V2PaymentResult> startViaServer({
    required BuildContext context,
    required V2Config config,
    required Uri createEndpoint,
    required String returnUrl,
    Map<String, dynamic>? createPayload, // what your server needs
    Uri? verifyEndpoint,                 // optional: your server verify URL
    String? appBarTitle,
  }) async {
    final res = await http.post(
      createEndpoint,
      headers: {
        'Content-Type': 'application/json',
        if (config.headers.isNotEmpty) ...config.headers,
      },
      body: jsonEncode(createPayload ?? {}),
    );

    if (config.enableLogs) {
      // ignore: avoid_print
      print('[V2] create ${res.statusCode} ${res.body}');
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw V2CheckoutException('Failed to create checkout: ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final url = body['checkoutUrl']?.toString();
    final reference = body['reference']?.toString();

    if (url == null) {
      throw V2CheckoutException('Missing checkoutUrl in server response');
    }

    // Open hosted checkout
    final interim = await openHostedCheckout(
      context: context,
      config: config,
      hostedCheckoutUrl: url,
      returnUrl: returnUrl,
      reference: reference,
      appBarTitle: appBarTitle,
    );

    // Optionally verify with your backend
    if (verifyEndpoint != null) {
      try {
        final vres = await http.get(
          verifyEndpoint,
          headers: {
            'Accept': 'application/json',
            if (config.headers.isNotEmpty) ...config.headers,
          },
        );
        if (config.enableLogs) {
          // ignore: avoid_print
          print('[V2] verify ${vres.statusCode} ${vres.body}');
        }
        if (vres.statusCode == 200) {
          final vbody = jsonDecode(vres.body);
          final verifiedStatus = _normalizeStatus(
            (vbody['status'] ?? interim.status).toString(),
          );
          return V2PaymentResult(
            reference: interim.reference,
            status: verifiedStatus,
            raw: {
              ...interim.raw,
              'verify': vbody,
            },
          );
        }
      } catch (e) {
        // ignore verify errors; return interim
      }
    }

    return interim;
  }

  static String _normalizeStatus(String s) {
    final t = s.toUpperCase();
    if (['PAID', 'SUCCESS', 'APPROVED', 'AUTHORISED', 'AUTHORIZED'].contains(t)) return 'SUCCESS';
    if (['FAILED', 'DECLINED', 'ERROR'].contains(t)) return 'FAILED';
    if (['CANCELLED', 'CANCELED', 'VOID'].contains(t)) return 'CANCELED';
    return 'PENDING';
  }
}
