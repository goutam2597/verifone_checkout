import 'v2_env.dart';

/// Runtime configuration provided by the package user.
class V2Config {
  /// Choose SANDBOX or PRODUCTION.
  final V2Environment environment;

  /// Your seller/merchant code (public identifier shown in buy-links).
  /// Not strictly required for opening a hosted URL, but useful for logs.
  final String merchantCode;

  /// Optional headers to attach to your own backend calls (if you use startViaServer).
  final Map<String, String> headers;

  /// Enable verbose logs.
  final bool enableLogs;

  /// Optional: any correlation/flow id to echo in the result.
  final String flowId;

  const V2Config({
    required this.environment,
    required this.merchantCode,
    this.headers = const {},
    this.enableLogs = true,
    this.flowId = '',
  });

  bool get isSandbox => environment == V2Environment.sandbox;
  bool get isProduction => environment == V2Environment.production;
}
