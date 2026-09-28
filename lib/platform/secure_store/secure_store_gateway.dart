abstract interface class SecureStoreGateway {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<bool> isAvailable();
}

class SecureStoreUnavailable implements Exception {
  final String message;
  SecureStoreUnavailable(this.message);
  @override
  String toString() => '安全存储不可用: $message';
}
