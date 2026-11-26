import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Errore restituito dal server o di rete, con un messaggio già leggibile.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Client HTTP verso le API REST del back-end.
class ApiClient {
  ApiClient({required this.baseUrl});

  /// Es. http://192.168.1.10:8090
  String baseUrl;

  /// Token di sessione dell'azienda autenticata (null = utente pubblico).
  String? token;

  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  Map<String, String> _headers({bool json = false}) => {
    if (json) 'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Il server non risponde ($baseUrl).');
    } on SocketException {
      throw ApiException('Impossibile contattare il server ($baseUrl). Controlla l\'indirizzo nelle impostazioni.');
    } on http.ClientException {
      throw ApiException('Impossibile contattare il server ($baseUrl).');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body = {};
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        body['error'] as String? ?? 'Errore del server (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> _get(String path) async =>
      _decode(await _send(() => http.get(_uri(path), headers: _headers())));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async =>
      _decode(await _send(() => http.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body))));

  // ---------------------------------------------------------------- auth (R1, R2, R3)

  Future<Company> register({required String name, required String email, required String password}) async {
    final data = await _post('/api/auth/register', {'name': name, 'email': email, 'password': password});
    return Company.fromJson(data['company'] as Map<String, dynamic>);
  }

  /// Restituisce il token e i dati dell'azienda.
  Future<(String, Company)> login({required String email, required String password}) async {
    final data = await _post('/api/auth/login', {'email': email, 'password': password});
    return (data['token'] as String, Company.fromJson(data['company'] as Map<String, dynamic>));
  }

  Future<void> logout() async {
    _decode(await _send(() => http.post(_uri('/api/auth/logout'), headers: _headers())));
  }

  Future<Company> me() async {
    final data = await _get('/api/auth/me');
    return Company.fromJson(data['company'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------- annunci (R4, R5)

  Future<List<Job>> listJobs() async {
    final data = await _get('/api/jobs');
    return (data['jobs'] as List).map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Job> getJob(int id) async {
    final data = await _get('/api/jobs/$id');
    return Job.fromJson(data['job'] as Map<String, dynamic>);
  }

  Future<Job> createJob({
    required String title,
    required String description,
    String? location,
    String? contractType,
  }) async {
    final data = await _post('/api/jobs', {
      'title': title,
      'description': description,
      'location': location,
      'contractType': contractType,
    });
    return Job.fromJson(data['job'] as Map<String, dynamic>);
  }

  Future<List<Job>> myJobs() async {
    final data = await _get('/api/my/jobs');
    return (data['jobs'] as List).map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------- candidature (R6, R7)

  Future<JobApplication> apply({
    required int jobId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? message,
    required String cvFilename,
    required Uint8List cvBytes,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/api/jobs/$jobId/applications'))
      ..fields.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (message != null && message.isNotEmpty) 'message': message,
      })
      ..files.add(http.MultipartFile.fromBytes('cv', cvBytes, filename: cvFilename));
    final res = await _send(() async => http.Response.fromStream(await req.send()));
    final data = _decode(res);
    return JobApplication.fromJson(data['application'] as Map<String, dynamic>);
  }

  Future<List<JobApplication>> applicationsForJob(int jobId) async {
    final data = await _get('/api/my/jobs/$jobId/applications');
    return (data['applications'] as List).map((a) => JobApplication.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<JobApplication> getApplication(int id) async {
    final data = await _get('/api/my/applications/$id');
    return JobApplication.fromJson(data['application'] as Map<String, dynamic>);
  }

  /// Scarica il curriculum (richiede il token dell'azienda).
  Future<Uint8List> downloadCv(int applicationId) async {
    final res = await _send(() => http.get(_uri('/api/my/applications/$applicationId/cv'), headers: _headers()));
    if (res.statusCode >= 400) _decode(res);
    return res.bodyBytes;
  }
}
