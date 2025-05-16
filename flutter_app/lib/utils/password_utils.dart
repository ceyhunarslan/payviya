import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';

class PasswordUtils {
  static const int _iterations = 1000;
  static const String _salt = "payviya_client_salt"; // Her uygulama için unique olmalı

  static String hashPassword(String password) {
    print('Starting password hashing process');
    print('Input password length: ${password.length}');
    
    // PBKDF2 ile ilk hash'leme (client-side)
    var bytes = utf8.encode(password + _salt);
    print('Password + salt encoded to bytes');
    
    var digest = sha256.convert(bytes);
    print('Initial SHA-256 hash created');
    
    for (var i = 0; i < _iterations; i++) {
      digest = sha256.convert(digest.bytes);
    }
    print('Completed $_iterations iterations of SHA-256');
    
    final result = base64.encode(digest.bytes);
    print('Final base64 encoded hash length: ${result.length}');
    
    return result;
  }

  static String hashPasswordForReset(String password) {
    return hashPassword(password);
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }
} 