import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_store_gateway.dart';

class SecureStoreImpl implements SecureStoreGateway {
  final FlutterSecureStorage _storage;
  static const _prefix = 'llm_profile_';

  SecureStoreImpl() : _storage = const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: '$_prefix$key', value: value);
  }

  @override
  Future<String?> read(String key) async {
    return _storage.read(key: '$_prefix$key');
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: '$_prefix$key');
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _storage.read(key: '${_prefix}__test__');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class FakeSecureStore implements SecureStoreGateway {
  final Map<String, String> _store = {};

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> isAvailable() async => true;
}
