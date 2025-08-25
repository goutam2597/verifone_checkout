import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ReturnHandler = void Function(Uri uri);

/// Opens [checkoutUrl] and intercepts [returnUrl] (custom scheme or https).
class CheckoutWebView extends StatefulWidget {
  final String checkoutUrl;
  final String returnUrl;   // e.g. myapp://payment-return or https://yourapp.com/return
  final ReturnHandler onReturn;
  final String? appBarTitle;

  const CheckoutWebView({
    super.key,
    required this.checkoutUrl,
    required this.returnUrl,
    required this.onReturn,
    this.appBarTitle,
  });

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  late final Uri _target;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _target = Uri.parse(widget.returnUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            // print('[V2 NAV] ${req.url}');
            if (uri != null && _isReturnUrl(uri)) {
              widget.onReturn(uri);
              if (mounted) Navigator.of(context).pop(); // close WebView
              return NavigationDecision.prevent;        // stop WebView from loading deeplink
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isReturnUrl(Uri u) {
    final custom = (u.scheme == _target.scheme) && (u.host == _target.host);
    final https  = (u.scheme == 'https' && _target.scheme == 'https'
        && u.host == _target.host && u.path == _target.path);
    final prefix = u.toString().startsWith(widget.returnUrl);
    return custom || https || prefix;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle ?? '2Checkout')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
