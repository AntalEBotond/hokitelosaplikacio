import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});
  @override
  String toString() => 'ApiException(${status ?? ''}): $message';
}

class ApiService {
  // IMPORTANT: On Android emulator use 10.0.2.2 instead of localhost.
  // On a real device, use your PC's LAN IP where PHP is running.
  static const String baseUrl = 'http://127.0.0.1:8088';

  Uri _url(String path) => Uri.parse('$baseUrl$path');

  Future<(String token, Map<String, dynamic> user)> login({required String username, required String password}) async {
    final res = await http.post(
      _url('/api/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['token'] != null) {
      return (data['token'] as String, Map<String, dynamic>.from(data['user'] as Map));
    }
    throw ApiException(data['error']?.toString() ?? 'Login failed', status: res.statusCode);
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.get(
      _url('/api/profile.php'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['profile'] != null) {
      return Map<String, dynamic>.from(data['profile'] as Map);
    }
    throw ApiException(data['error']?.toString() ?? 'Cannot load profile', status: res.statusCode);
  }

  Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> payload) async {
    final res = await http.post(
      _url('/api/profile.php'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['profile'] != null) {
      return Map<String, dynamic>.from(data['profile'] as Map);
    }
    throw ApiException(data['error']?.toString() ?? 'Cannot update profile', status: res.statusCode);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return (body is Map<String, dynamic>) ? body : <String, dynamic>{'data': body};
    } catch (_) {
      return <String, dynamic>{'error': 'Invalid JSON', 'raw': res.body};
    }
  }

  Future<String> uploadAvatarBytes(String token, List<int> bytes, {String filename = 'avatar.jpg', String contentType = 'image/jpeg'}) async {
    final req = http.MultipartRequest('POST', _url('/api/avatar.php'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: _mediaType(contentType)));
    final res = await http.Response.fromStream(await req.send());
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['avatar_url'] != null) {
      return data['avatar_url'] as String;
    }
    throw ApiException(data['error']?.toString() ?? 'Upload failed', status: res.statusCode);
  }

  Future<String> uploadAvatarPath(String token, String path, {String? filename, String? contentType}) async {
    final req = http.MultipartRequest('POST', _url('/api/avatar.php'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', path, filename: filename, contentType: _mediaType(contentType)));
    final res = await http.Response.fromStream(await req.send());
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['avatar_url'] != null) {
      return data['avatar_url'] as String;
    }
    throw ApiException(data['error']?.toString() ?? 'Upload failed', status: res.statusCode);
  }

  Future<void> deleteAvatar(String token) async {
    final res = await http.delete(_url('/api/avatar.php'), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _decode(res);
      throw ApiException(data['error']?.toString() ?? 'Delete failed', status: res.statusCode);
    }
  }

  Future<String> uploadBannerBytes(String token, List<int> bytes, {String filename = 'banner.jpg', String contentType = 'image/jpeg'}) async {
    final req = http.MultipartRequest('POST', _url('/api/banner.php'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: _mediaType(contentType)));
    final res = await http.Response.fromStream(await req.send());
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['banner_url'] != null) {
      return data['banner_url'] as String;
    }
    throw ApiException(data['error']?.toString() ?? 'Upload failed', status: res.statusCode);
  }

  Future<String> uploadBannerPath(String token, String path, {String? filename, String? contentType}) async {
    final req = http.MultipartRequest('POST', _url('/api/banner.php'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', path, filename: filename, contentType: _mediaType(contentType)));
    final res = await http.Response.fromStream(await req.send());
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['banner_url'] != null) {
      return data['banner_url'] as String;
    }
    throw ApiException(data['error']?.toString() ?? 'Upload failed', status: res.statusCode);
  }

  Future<void> deleteBanner(String token) async {
    final res = await http.delete(_url('/api/banner.php'), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _decode(res);
      throw ApiException(data['error']?.toString() ?? 'Delete failed', status: res.statusCode);
    }
  }

  // Helper to build MediaType without importing http_parser directly
  dynamic _mediaType(String? contentType) {
    if (contentType == null) return null;
    try {
      final parts = contentType.split('/');
      if (parts.length == 2) {
        // http.MultipartFile expects a MediaType from package:http_parser, but
        // it accepts a dynamic. Avoid hard dep; null is also acceptable.
        // However, when null, http will infer from filename. We'll return null if parsing fails.
        // Leaving as null keeps compatibility.
      }
    } catch (_) {}
    return null;
  }
}
