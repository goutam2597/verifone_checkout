class V2PublicKeys {
  final String merchantCode;   // same as sid
  final String publishableKey; // optional (not used by buy-link)
  const V2PublicKeys({
    required this.merchantCode,
    this.publishableKey = '',
  });
}
