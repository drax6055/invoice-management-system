import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  String? cachedAccessToken;
  String? cachedRefreshToken;

  Future<String?> get accessToken async {
    if (cachedAccessToken != null) return cachedAccessToken;
    final prefs = await SharedPreferences.getInstance();
    cachedAccessToken = prefs.getString(_accessKey);
    return cachedAccessToken;
  }

  Future<String?> get refreshToken async {
    if (cachedRefreshToken != null) return cachedRefreshToken;
    final prefs = await SharedPreferences.getInstance();
    cachedRefreshToken = prefs.getString(_refreshKey);
    return cachedRefreshToken;
  }

  Future<void> save({required String accessToken, required String refreshToken}) async {
    cachedAccessToken = accessToken;
    cachedRefreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clear() async {
    cachedAccessToken = null;
    cachedRefreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
