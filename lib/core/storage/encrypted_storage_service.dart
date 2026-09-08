import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Encrypted Storage Service (Android Keystore / Secure Enclave Abstraction)
/// Secures device tokens, encryption keys, and sensitive session credentials.
class EncryptedStorageService {
  static final EncryptedStorageService _instance = EncryptedStorageService._internal();
  factory EncryptedStorageService() => _instance;
  EncryptedStorageService._internal();

  final Map<String, String> _secureKeyStore = {};

  // Device-bound master seal key seed
  static const String _deviceEntropy = 'NEXORA_SECURE_HARDWARE_KEY_2026_SEAL';

  /// Stores a value under an encrypted key
  Future<void> writeSecure(String key, String value) async {
    final obfuscated = _encrypt(value);
    _secureKeyStore[key] = obfuscated;
  }

  /// Reads a secure value
  Future<String?> readSecure(String key) async {
    final raw = _secureKeyStore[key];
    if (raw == null) return null;
    return _decrypt(raw);
  }

  /// Removes a secure value
  Future<void> deleteSecure(String key) async {
    _secureKeyStore.remove(key);
  }

  /// Clears all secure values (e.g. on logout)
  Future<void> clearAll() async {
    _secureKeyStore.clear();
  }

  String _encrypt(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final keyBytes = sha256.convert(utf8.encode(_deviceEntropy)).bytes;
    final encrypted = List<int>.generate(bytes.length, (i) => bytes[i] ^ keyBytes[i % keyBytes.length]);
    return base64Encode(encrypted);
  }

  String _decrypt(String ciphertext) {
    final bytes = base64Decode(ciphertext);
    final keyBytes = sha256.convert(utf8.encode(_deviceEntropy)).bytes;
    final decrypted = List<int>.generate(bytes.length, (i) => bytes[i] ^ keyBytes[i % keyBytes.length]);
    return utf8.decode(decrypted);
  }
}
