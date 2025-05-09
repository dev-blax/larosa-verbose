import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/impl.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/asn1.dart';

import 'log_service.dart';

class EncryptionService {
  static const String _keyStorageKey = 'symmetric_encryption_key';
  static const String _e2ePreferenceKey = 'e2e_encryption_enabled';
  static const String _publicKeyKey = 'e2e_public_key';
  static const String _privateKeyKey = 'e2e_private_key';
  static const String _e2ePasswordKey = 'e2e_password';
  static const String _e2ePasswordSaltKey = 'e2e_password_salt';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  // Generates a 256-bit symmetric key and stores it securely
  Future<Uint8List> generateAndStoreKey() async {
    final random = Random.secure();
    final key = Uint8List(32); // 256-bit key
    
    // Fill the key with secure random bytes
    for (var i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }

    // Store the key securely
    final keyBase64 = base64Encode(key);
    await _secureStorage.write(
      key: _keyStorageKey,
      value: keyBase64,
      aOptions: _getAndroidOptions(),
    );

    return key;
  }

  // Retrieves the stored symmetric key
  Future<Uint8List?> getStoredKey() async {
    final keyBase64 = await _secureStorage.read(
      key: _keyStorageKey,
      aOptions: _getAndroidOptions(),
    );
    if (keyBase64 == null) return null;
    return base64Decode(keyBase64);
  }

  // Retrieves the base64-encoded version of the stored symmetric key
  Future<String?> getStoredKeyBase64() async {
    return await _secureStorage.read(
      key: _keyStorageKey,
      aOptions: _getAndroidOptions(),
    );
  }

  // Encrypts data using AES-GCM
  Future<String> encrypt(String plainText, Uint8List key) async {
    final random = Random.secure();
    final nonce = Uint8List(12); // 96-bit nonce for GCM
    for (var i = 0; i < nonce.length; i++) {
      nonce[i] = random.nextInt(256);
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

    final plainBytes = utf8.encode(plainText);
    final cipherText = cipher.process(Uint8List.fromList(plainBytes));

    // Combine nonce and ciphertext
    final result = Uint8List(nonce.length + cipherText.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, cipherText);
    
    return base64Encode(result);
  }

  // Decrypts data using AES-GCM
  Future<String> decrypt(String encryptedData, Uint8List key) async {
    final data = base64Decode(encryptedData);
    final nonce = data.sublist(0, 12); // Extract nonce
    final cipherText = data.sublist(12); // Extract ciphertext

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

    final plainBytes = cipher.process(cipherText);
    return utf8.decode(plainBytes);
  }

  // Store end-to-end encryption preference
  Future<void> setE2EEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _e2ePreferenceKey,
      value: enabled.toString(),
      aOptions: _getAndroidOptions(),
    );
  }

  // Retrieve end-to-end encryption preference
  Future<bool> isE2EEnabled() async {
    final value = await _secureStorage.read(
      key: _e2ePreferenceKey,
      aOptions: _getAndroidOptions(),
    );
    // Default to false if no preference is stored
    return value?.toLowerCase() == 'true';
  }

  // Store end-to-end encryption keys
  Future<void> storeE2EKeys(String publicKey, String encryptedPrivateKey) async {
    await Future.wait([
      _secureStorage.write(
        key: _publicKeyKey,
        value: publicKey,
        aOptions: _getAndroidOptions(),
      ),
      _secureStorage.write(
        key: _privateKeyKey,
        value: encryptedPrivateKey,
        aOptions: _getAndroidOptions(),
      ),
    ]);
  }

  // Retrieve public key
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(
      key: _publicKeyKey,
      aOptions: _getAndroidOptions(),
    );
  }

  // Retrieve encrypted private key
  Future<String?> getEncryptedPrivateKey() async {
    return await _secureStorage.read(
      key: _privateKeyKey,
      aOptions: _getAndroidOptions(),
    );
  }

  // Delete E2E keys
  Future<void> deleteE2EKeys() async {
    await Future.wait([
      _secureStorage.delete(
        key: _publicKeyKey,
        aOptions: _getAndroidOptions(),
      ),
      _secureStorage.delete(
        key: _privateKeyKey,
        aOptions: _getAndroidOptions(),
      ),
    ]);
  }

  // Store E2E password securely with additional encryption
  Future<void> storeE2EPassword(String password) async {
    // Generate a random salt for this password
    final salt = _generateRandomBytes(32);
    final key = await _generateKeyFromPassword(password, salt);
    
    // Encrypt the password with the derived key
    final nonce = _generateRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

    final passwordBytes = utf8.encode(password);
    final encryptedPassword = cipher.process(Uint8List.fromList(passwordBytes));
    
    // Combine nonce and encrypted password
    final encryptedData = Uint8List(nonce.length + encryptedPassword.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, encryptedPassword);

    // Store both the encrypted password and its salt
    await Future.wait([
      _secureStorage.write(
        key: _e2ePasswordKey,
        value: base64Encode(encryptedData),
        aOptions: _getAndroidOptions(),
      ),
      _secureStorage.write(
        key: _e2ePasswordSaltKey,
        value: base64Encode(salt),
        aOptions: _getAndroidOptions(),
      ),
    ]);
  }

  // Verify if the provided password matches the stored one
  Future<bool> verifyE2EPassword(String password) async {
    try {
      final encryptedData = await _secureStorage.read(
        key: _e2ePasswordKey,
        aOptions: _getAndroidOptions(),
      );
      final saltStr = await _secureStorage.read(
        key: _e2ePasswordSaltKey,
        aOptions: _getAndroidOptions(),
      );

      if (encryptedData == null || saltStr == null) return false;

      final salt = base64Decode(saltStr);
      final key = await _generateKeyFromPassword(password, salt);
      
      final data = base64Decode(encryptedData);
      final nonce = data.sublist(0, 12);
      final cipherText = data.sublist(12);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      try {
        final decryptedBytes = cipher.process(cipherText);
        final decryptedPassword = utf8.decode(decryptedBytes);
        return decryptedPassword == password;
      } on ArgumentError {
        return false; // Decryption failed - wrong password
      }
    } catch (e) {
      // LogService.logError('Error verifying E2E password: $e');
      return false;
    }
  }

  // Retrieve the stored E2E password
  Future<String?> getE2EPassword() async {
    try {
      final encryptedData = await _secureStorage.read(
        key: _e2ePasswordKey,
        aOptions: _getAndroidOptions(),
      );
      final saltStr = await _secureStorage.read(
        key: _e2ePasswordSaltKey,
        aOptions: _getAndroidOptions(),
      );

      if (encryptedData == null || saltStr == null) return null;

      final data = base64Decode(encryptedData);
      final salt = base64Decode(saltStr);
      
      // Use a device-specific key for additional security
      final deviceKey = await _generateDeviceKey(salt);
      
      final nonce = data.sublist(0, 12);
      final cipherText = data.sublist(12);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(deviceKey), 128, nonce, Uint8List(0)));

      try {
        final decryptedBytes = cipher.process(cipherText);
        return utf8.decode(decryptedBytes);
      } on ArgumentError {
        return null; // Decryption failed
      }
    } catch (e) {
      return null;
    }
  }

  // Encrypt data with RSA public key
  Future<String> encryptWithPublicKey(String data, String publicKeyBase64) async {
    try {
      // Decode the base64 public key
      final publicKeyBytes = base64Decode(publicKeyBase64);
      
      // Parse ASN.1 structure
      final parser = ASN1Parser(publicKeyBytes);
      final topSequence = parser.nextObject() as ASN1Sequence;
      
      // The public key sequence contains another sequence with algorithm identifier
      // and the actual key bit string
      //final algorithmSequence = topSequence.elements![0] as ASN1Sequence;
      final publicKeyBitString = topSequence.elements![1] as ASN1BitString;
      
      // Parse the public key bit string
      final publicKeyParser = ASN1Parser(publicKeyBitString.stringValues as Uint8List);
      final publicKeySequence = publicKeyParser.nextObject() as ASN1Sequence;
      
      final modulus = (publicKeySequence.elements![0] as ASN1Integer).integer!;
      final exponent = (publicKeySequence.elements![1] as ASN1Integer).integer!;

      final rsaPublicKey = RSAPublicKey(
        modulus,
        exponent,
      );

      // Initialize RSA engine
      final cipher = RSAEngine()
        ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));

      // Convert data to bytes and encrypt
      final dataBytes = utf8.encode(data);
      final encryptedBytes = cipher.process(Uint8List.fromList(dataBytes));

      // Return base64 encoded encrypted data
      return base64Encode(encryptedBytes);
    } catch (e) {
      // LogService.logError('Error encrypting with public key: $e');
      rethrow;
    }
  }

  // Generate a device-specific key for password encryption
  Future<Uint8List> _generateDeviceKey(Uint8List salt) async {
    // Use a constant device-specific value (you may want to use a more secure device identifier)
    final deviceId = 'X2X2X2X3X3X3X2';
    return _generateKeyFromPassword(deviceId, salt);
  }

  // Delete stored E2E password
  Future<void> deleteE2EPassword() async {
    await Future.wait([
      _secureStorage.delete(
        key: _e2ePasswordKey,
        aOptions: _getAndroidOptions(),
      ),
      _secureStorage.delete(
        key: _e2ePasswordSaltKey,
        aOptions: _getAndroidOptions(),
      ),
    ]);
  }

  // Delete all encryption-related data
  Future<void> deleteAllEncryptedData() async {
    try {
      await Future.wait([
        // Delete symmetric key
        _secureStorage.delete(
          key: _keyStorageKey,
          aOptions: _getAndroidOptions(),
        ),
        // Delete E2E preference
        _secureStorage.delete(
          key: _e2ePreferenceKey,
          aOptions: _getAndroidOptions(),
        ),
        // Delete public and private keys
        _secureStorage.delete(
          key: _publicKeyKey,
          aOptions: _getAndroidOptions(),
        ),
        _secureStorage.delete(
          key: _privateKeyKey,
          aOptions: _getAndroidOptions(),
        ),
        // Delete E2E password and salt
        _secureStorage.delete(
          key: _e2ePasswordKey,
          aOptions: _getAndroidOptions(),
        ),
        _secureStorage.delete(
          key: _e2ePasswordSaltKey,
          aOptions: _getAndroidOptions(),
        ),
      ]);
    } catch (e) {
      // LogService.logError('Error deleting encrypted data: $e');
      rethrow;
    }
  }

  // Decrypt private key using password
  Future<Uint8List> decryptPrivateKey(String encryptedPrivateKey, String password) async {
    try {
      // Get the salt used for password
      final saltStr = await _secureStorage.read(
        key: _e2ePasswordSaltKey,
        aOptions: _getAndroidOptions(),
      );
      
      if (saltStr == null) throw Exception('Password salt not found');
      
      final salt = base64Decode(saltStr);
      // Generate key from password
      final key = await _generateKeyFromPassword(password, salt);
      
      // Decrypt the private key using the derived key
      final decryptedPrivateKey = await decrypt(encryptedPrivateKey, key);
      return Uint8List.fromList(utf8.encode(decryptedPrivateKey));
    } catch (e) {
      LogService.logError('Error decrypting private key: $e');
      rethrow;
    }
  }

  // Helper to generate a key from password and salt using PBKDF2
  Future<Uint8List> _generateKeyFromPassword(String password, Uint8List salt) async {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, 100000, 32)); // 100,000 iterations, 256-bit key
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}