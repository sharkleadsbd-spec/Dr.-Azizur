import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credentials live in Android Keystore-backed secure storage.
/// Only a salted, iterated SHA-256 hash is stored – never the plain password.
class Auth {
  static const _s = FlutterSecureStorage();
  static const _demo = {
    'doctor': ['doctor', 'Doctor@123'],
    'assistant': ['assistant', 'Assist@123'],
  };

  static String _hash(String pw, String salt) {
    var d = sha256.convert(utf8.encode('$salt:$pw'));
    for (var i = 0; i < 20000; i++) {
      d = sha256.convert([...d.bytes, ...utf8.encode(salt)]);
    }
    return d.toString();
  }

  static String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static Future<void> seed() async {
    for (final e in _demo.entries) {
      if (await _s.read(key: 'cred_${e.key}') == null) {
        final salt = _salt();
        await _s.write(
            key: 'cred_${e.key}',
            value: jsonEncode({'user': e.value[0], 'salt': salt, 'hash': _hash(e.value[1], salt)}));
      }
    }
  }

  static Future<bool> login(String role, String user, String pw) async {
    final raw = await _s.read(key: 'cred_$role');
    if (raw == null) return false;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final okUser = (m['user'] as String).toLowerCase() == user.toLowerCase();
    final okPw = _hash(pw, m['salt'] as String) == m['hash'];
    return okUser && okPw;
  }
}
