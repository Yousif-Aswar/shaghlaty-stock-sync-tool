import 'package:intl/intl.dart';

// ─── Product ──────────────────────────────────────────────────────────────────

class ProductVariant {
  final String id;
  final String? displayName;
  final String? name;
  final String? internalRef;
  final String? sku;
  final String? barcode;

  ProductVariant({
    required this.id,
    this.displayName,
    this.name,
    this.internalRef,
    this.sku,
    this.barcode,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        id: j['id'].toString(),
        displayName: j['display_name'] as String?,
        name: j['name'] as String?,
        internalRef: j['internal_ref'] as String?,
        sku: j['sku'] as String?,
        barcode: j['barcode'] as String?,
      );

  String get title => displayName ?? name ?? '(Unnamed Product)';
}

// ─── Quantities ───────────────────────────────────────────────────────────────

class ErpQty {
  final double? onHand;
  final double? reserved;
  ErpQty({this.onHand, this.reserved});

  factory ErpQty.fromJson(Map<String, dynamic> j) => ErpQty(
        onHand: _d(j['qty_on_hand']),
        reserved: _d(j['qty_reserved']),
      );
}

class ShaghlatyQty {
  final double? onHand;
  final double? reserved;
  ShaghlatyQty({this.onHand, this.reserved});

  factory ShaghlatyQty.fromJson(Map<String, dynamic> j) => ShaghlatyQty(
        onHand: _d(j['on_hand']),
        reserved: _d(j['reserved']),
      );
}

// ─── Sale Order Line ──────────────────────────────────────────────────────────

class SaleOrderLine {
  final String? orderName;
  final double qty;
  SaleOrderLine({this.orderName, required this.qty});

  factory SaleOrderLine.fromJson(Map<String, dynamic> j) => SaleOrderLine(
        orderName: (j['sale_order'] as Map<String, dynamic>?)?['name'] as String?,
        qty: _d(j['product_uom_qty']) ?? 0,
      );
}

// ─── Sync Log ─────────────────────────────────────────────────────────────────

class SyncLog {
  final String id;
  final String? performedBy;
  final String? internalRef;
  final String? barcode;
  final double targetQty;
  final double? erpBefore, erpAfter;
  final double? shaghBefore, shaghAfter, shaghDelta;
  final bool erpSuccess, shaghSuccess;
  final String? errorDetail;
  final DateTime? created;

  SyncLog({
    required this.id,
    this.performedBy,
    this.internalRef,
    this.barcode,
    required this.targetQty,
    this.erpBefore,
    this.erpAfter,
    this.shaghBefore,
    this.shaghAfter,
    this.shaghDelta,
    required this.erpSuccess,
    required this.shaghSuccess,
    this.errorDetail,
    this.created,
  });

  factory SyncLog.fromJson(Map<String, dynamic> j) => SyncLog(
        id: j['id'].toString(),
        performedBy:
            (j['create_user'] as Map<String, dynamic>?)?['username'] as String?,
        internalRef: j['internal_ref'] as String?,
        barcode: j['barcode'] as String?,
        targetQty: _d(j['target_quantity']) ?? 0,
        erpBefore: _d(j['erp_qty_before']),
        erpAfter: _d(j['erp_qty_after']),
        shaghBefore: _d(j['shaghlaty_qty_before']),
        shaghAfter: _d(j['shaghlaty_qty_after']),
        shaghDelta: _d(j['shaghlaty_delta']),
        erpSuccess: j['erp_success'] == true,
        shaghSuccess: j['shaghlaty_success'] == true,
        errorDetail: j['error_detail'] as String?,
        created: j['created'] != null
            ? DateTime.tryParse(j['created'] as String)
            : null,
      );

  String get formattedDate => created == null
      ? '—'
      : DateFormat('MMM d, y  HH:mm').format(created!.toLocal());
}

class SyncLogPage {
  final int currentPage;
  final int numPages;
  final int? nextPage;
  final int total;
  final List<SyncLog> results;

  SyncLogPage({
    required this.currentPage,
    required this.numPages,
    this.nextPage,
    required this.total,
    required this.results,
  });

  factory SyncLogPage.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => SyncLog.fromJson(e as Map<String, dynamic>))
        .toList();
    return SyncLogPage(
      currentPage: (j['current_page'] as num?)?.toInt() ?? 1,
      numPages: (j['last_page'] as num?)?.toInt() ?? 1,
      nextPage: j['next_page_url'] != null ? ((j['current_page'] as num?)?.toInt() ?? 1) + 1 : null,
      total: (j['total'] as num?)?.toInt() ?? 0,
      results: list,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

double? _d(dynamic v) =>
    v == null ? null : double.tryParse(v.toString());

String fmtQty(double? v) {
  if (v == null) return '—';
  return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}
