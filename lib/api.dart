import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

const _base = 'https://devserv1.aswar.solutions';

class Api {
  Api._();
  static final Api instance = Api._();

  String? _token;
  void setToken(String t) => _token = t;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$_base/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': username, 'password': password, 'grant_type': 'password'}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body['message'] ?? 'Login failed (${res.statusCode})');
    }
    final data = body['data'] ?? body;
    final token = (data as Map<String, dynamic>)['access_token'] as String?;
    if (token == null) throw Exception('No access token in response');
    return token;
  }

  // ─── Product search ────────────────────────────────────────────────────────

  Future<ProductVariant?> findProduct(String query) async {
    final q = Uri.encodeComponent(query);
    for (final path in [
      'inventory/product-variant/?barcode=$q&page_size=1',
      'inventory/product-variant/?internal_ref=$q&page_size=1',
    ]) {
      final res =
          await http.get(Uri.parse('$_base/$path'), headers: _headers);
      _check401(res);
      if (res.statusCode < 200 || res.statusCode >= 300) continue;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['data'] ?? body['results'] ?? body;
      if (list is List && list.isNotEmpty) {
        return ProductVariant.fromJson(list[0] as Map<String, dynamic>);
      }
    }
    return null;
  }

  // ─── Quantities ────────────────────────────────────────────────────────────

  Future<ErpQty> getErpQty(String productId) async {
    final res = await http.get(
      Uri.parse('$_base/inventory/product-variant/$productId/'),
      headers: _headers,
    );
    _check401(res);
    _checkOk(res, 'Failed to load ERP quantity');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ErpQty.fromJson((body['data'] ?? body) as Map<String, dynamic>);
  }

  Future<ShaghlatyQty> getShaghlatyQty(String productId) async {
    final res = await http.get(
      Uri.parse('$_base/inventory/product-variant/$productId/shaghlaty-quantity/'),
      headers: _headers,
    );
    _check401(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(
          err['detail'] ?? err['error'] ?? 'Shaghlaty error (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ShaghlatyQty.fromJson(
        (body['data'] ?? body) as Map<String, dynamic>);
  }

  // ─── Draft sale orders ─────────────────────────────────────────────────────

  Future<List<SaleOrderLine>> getDraftOrders(String productId) async {
    final res = await http.post(
      Uri.parse(
          '$_base/sales/sale-order-line/filter-query?page=1&page_size=100&ordering=-created'),
      headers: _headers,
      body: jsonEncode({
        'domain': {
          'and': [
            ['product', 'exact', productId],
            ['sale_order__state', 'exact', 'draft'],
            {'and': []},
          ]
        },
        'return_archive': false,
        'group_by': '',
      }),
    );
    _check401(res);
    _checkOk(res, 'Failed to load orders');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rows =
        body['data']?['results'] ?? body['data'] ?? body['results'] ?? body;
    if (rows is! List) return [];
    return rows
        .map((e) => SaleOrderLine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Sync ─────────────────────────────────────────────────────────────────

  Future<SyncResponse> syncQuantity(String productId, double quantity) async {
    final res = await http.post(
      Uri.parse('$_base/inventory/product-variant/$productId/sync-quantity/'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    _check401(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] ?? body;
    return SyncResponse(
      statusCode: res.statusCode,
      message: (data as Map<String, dynamic>)['detail'] as String? ??
          body['message'] as String? ??
          '',
    );
  }

  // ─── Audit log ─────────────────────────────────────────────────────────────

  Future<SyncLogPage> getSyncLogs({int page = 1, int pageSize = 10}) async {
    final res = await http.get(
      Uri.parse('$_base/inventory/quantity-sync-log/?page=$page&page_size=$pageSize'),
      headers: _headers,
    );
    _check401(res);
    _checkOk(res, 'Failed to load audit log');
    return SyncLogPage.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  void _check401(http.Response res) {
    if (res.statusCode == 401) throw const SessionExpiredException();
  }

  void _checkOk(http.Response res, String msg) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$msg (${res.statusCode})');
    }
  }
}

class SyncResponse {
  final int statusCode;
  final String message;
  SyncResponse({required this.statusCode, required this.message});

  bool get isSuccess => statusCode >= 200 && statusCode < 300 && statusCode != 207;
  bool get isPartial => statusCode == 207;
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();
  @override
  String toString() => 'Session expired';
}
