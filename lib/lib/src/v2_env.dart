/// Supported environments for Verifone 2Checkout.
enum V2Environment { sandbox, production }

extension V2EnvironmentX on V2Environment {
  /// Base UI/portal hostnames (for reference/logging only).
  String get baseHost => switch (this) {
    V2Environment.sandbox    => 'sandbox.2checkout.com',
    V2Environment.production => 'secure.2checkout.com',
  };

  String get label => this == V2Environment.sandbox ? 'SANDBOX' : 'PRODUCTION';
}
