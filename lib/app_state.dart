import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

/// Stato globale dell'app: indirizzo del server e sessione dell'azienda.
///
/// Il token viene salvato in locale, così l'azienda resta autenticata
/// anche dopo la chiusura dell'app (fino al logout).
class AppState extends ChangeNotifier {
  AppState(this._prefs) : api = ApiClient(baseUrl: _prefs.getString(_kServerUrl) ?? defaultServerUrl) {
    api.token = _prefs.getString(_kToken);
    final companyJson = _prefs.getString(_kCompany);
    if (api.token != null && companyJson != null) {
      _company = Company.fromJson(jsonDecode(companyJson) as Map<String, dynamic>);
    }
  }

  static const _kServerUrl = 'server_url';
  static const _kToken = 'auth_token';
  static const _kCompany = 'auth_company';

  /// Indirizzo predefinito: impostabile con --dart-define=API_URL=http://IP:8090.
  /// Altrimenti 10.0.2.2 (= il computer, visto dall'emulatore Android) o localhost.
  static String get defaultServerUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8090';
    return 'http://localhost:8090';
  }

  final SharedPreferences _prefs;
  final ApiClient api;

  Company? _company;
  Company? get company => _company;
  bool get isLoggedIn => api.token != null && _company != null;

  String get serverUrl => api.baseUrl;

  Future<void> setServerUrl(String url) async {
    api.baseUrl = url.trim();
    await _prefs.setString(_kServerUrl, api.baseUrl);
    notifyListeners();
  }

  /// Verifica all'avvio che il token salvato sia ancora valido.
  Future<void> validateSession() async {
    if (api.token == null) return;
    try {
      _company = await api.me();
      await _prefs.setString(_kCompany, jsonEncode(_company!.toJson()));
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await clearSession();
      // In caso di errore di rete si mantiene la sessione locale.
    }
  }

  Future<void> login(String email, String password) async {
    final (token, company) = await api.login(email: email, password: password);
    api.token = token;
    _company = company;
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kCompany, jsonEncode(company.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout(); // invalida il token anche sul server
    } catch (_) {
      // Anche se il server non è raggiungibile, la sessione locale va chiusa.
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    api.token = null;
    _company = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kCompany);
    notifyListeners();
  }
}
