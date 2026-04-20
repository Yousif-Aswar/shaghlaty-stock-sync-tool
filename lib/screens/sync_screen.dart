import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'login.dart';

class SyncScreen extends StatefulWidget {
  final VoidCallback? onActivity;
  const SyncScreen({super.key, this.onActivity});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _qtyCtrl = TextEditingController();

  ProductVariant? _product;
  bool _searching = false;
  bool _syncing = false;

  ErpQty? _erp;
  bool _loadingErp = false;
  ShaghlatyQty? _shagh;
  bool _loadingShagh = false;

  List<SaleOrderLine>? _orders;
  bool _loadingOrders = false;

  String? _globalMsg;
  String _globalType = 'info';
  String? _syncMsg;
  String _syncType = 'info';

  @override
  void initState() {
    super.initState();
    // Always keep focus on the search field so the physical scanner
    // (which emits keystrokes + Enter via the Type-C port) hits it directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _activity() => widget.onActivity?.call();

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _product = null;
      _erp = null;
      _shagh = null;
      _orders = null;
      _globalMsg = null;
      _syncMsg = null;
    });
    _searchFocus.requestFocus();
  }

  void _setGlobal(String msg, String type) =>
      setState(() { _globalMsg = msg; _globalType = type; });

  void _setSync(String msg, String type) =>
      setState(() { _syncMsg = msg; _syncType = type; });

  Future<void> _search() async {
    _activity();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _searching = true;
      _product = null;
      _erp = null;
      _shagh = null;
      _orders = null;
      _globalMsg = null;
      _syncMsg = null;
    });

    try {
      final p = await Api.instance.findProduct(q);
      if (p == null) {
        _setGlobal('No product found for: "$q"', 'error');
        return;
      }
      setState(() => _product = p);
      _loadErp(p);
      _loadShagh(p);
      _loadOrders(p);
    } on SessionExpiredException {
      _sessionExpired();
    } on Exception catch (e) {
      _setGlobal('Search error: ${e.toString().replaceFirst("Exception: ", "")}', 'error');
    } finally {
      if (mounted) {
        setState(() => _searching = false);
        // Return focus to the search field so the scanner is ready for the next item.
        _searchFocus.requestFocus();
      }
    }
  }

  Future<void> _loadErp(ProductVariant p) async {
    setState(() => _loadingErp = true);
    try {
      final qty = await Api.instance.getErpQty(p.id);
      if (mounted) setState(() { _erp = qty; _loadingErp = false; });
    } on SessionExpiredException {
      _sessionExpired();
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loadingErp = false);
        _setSync('ERP error: ${e.toString().replaceFirst("Exception: ", "")}', 'error');
      }
    }
  }

  Future<void> _loadShagh(ProductVariant p) async {
    setState(() => _loadingShagh = true);
    try {
      final qty = await Api.instance.getShaghlatyQty(p.id);
      if (mounted) setState(() { _shagh = qty; _loadingShagh = false; });
    } on SessionExpiredException {
      _sessionExpired();
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loadingShagh = false);
        _setSync('Shaghlaty: ${e.toString().replaceFirst("Exception: ", "")}', 'warning');
      }
    }
  }

  Future<void> _loadOrders(ProductVariant p) async {
    setState(() => _loadingOrders = true);
    try {
      final orders = await Api.instance.getDraftOrders(p.id);
      if (mounted) setState(() { _orders = orders; _loadingOrders = false; });
    } on Exception {
      if (mounted) setState(() { _orders = []; _loadingOrders = false; });
    }
  }

  Future<void> _refresh() async {
    if (_product == null) return;
    _activity();
    setState(() { _erp = null; _shagh = null; _syncMsg = null; });
    _loadErp(_product!);
    _loadShagh(_product!);
  }

  Future<void> _sync() async {
    if (_product == null) return;
    _activity();
    _searchFocus.requestFocus();
    final s = _qtyCtrl.text.trim();
    if (s.isEmpty) { _setSync('Please enter a quantity to sync.', 'warning'); return; }
    final qty = double.tryParse(s);
    if (qty == null || qty < 0) { _setSync('Please enter a valid non-negative number.', 'error'); return; }

    setState(() { _syncing = true; _syncMsg = null; });
    try {
      final r = await Api.instance.syncQuantity(_product!.id, qty);
      if (r.isSuccess) {
        _setSync('Synced! Quantity set to ${fmtQty(qty)}.', 'success');
        await Future.delayed(const Duration(milliseconds: 600));
        _refresh();
      } else if (r.isPartial) {
        _setSync('Partial sync — ${r.message}', 'warning');
        await Future.delayed(const Duration(milliseconds: 600));
        _refresh();
      } else {
        _setSync('Failed: ${r.message}', 'error');
      }
    } on SessionExpiredException {
      _sessionExpired();
    } on Exception catch (e) {
      _setSync('Sync error: ${e.toString().replaceFirst("Exception: ", "")}', 'error');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _sessionExpired() {
    Api.instance.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(sessionExpired: true)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _activity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search / scan field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: true,
                    style: const TextStyle(color: C.text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Scan barcode or enter internal ref…',
                      prefixIcon: const Icon(Icons.barcode_reader, color: C.muted, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: C.muted, size: 18),
                              onPressed: _clearSearch,
                              tooltip: 'Clear',
                            )
                          : null,
                    ),
                    onChanged: (_) => _activity(),
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  child: _searching
                      ? const _Spinner()
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect the barcode scanner to the Type-C port — it will type directly into the field above',
              style: TextStyle(fontSize: 11, color: C.muted),
            ),
            const SizedBox(height: 16),

            if (_globalMsg != null && _product == null) ...[
              StatusBar(msg: _globalMsg!, type: _globalType),
              const SizedBox(height: 16),
            ],

            if (_product != null) ...[
              _ProductCard(
                product: _product!,
                erp: _erp,
                loadingErp: _loadingErp,
                shagh: _shagh,
                loadingShagh: _loadingShagh,
                qtyCtrl: _qtyCtrl,
                syncing: _syncing,
                syncMsg: _syncMsg,
                syncType: _syncType,
                onSync: _sync,
                onRefresh: _refresh,
                onActivity: _activity,
              ),
              const SizedBox(height: 14),
              _DraftOrders(loading: _loadingOrders, orders: _orders),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductVariant product;
  final ErpQty? erp;
  final bool loadingErp;
  final ShaghlatyQty? shagh;
  final bool loadingShagh;
  final TextEditingController qtyCtrl;
  final bool syncing;
  final String? syncMsg;
  final String syncType;
  final VoidCallback onSync, onRefresh, onActivity;

  const _ProductCard({
    required this.product,
    this.erp,
    required this.loadingErp,
    this.shagh,
    required this.loadingShagh,
    required this.qtyCtrl,
    required this.syncing,
    this.syncMsg,
    required this.syncType,
    required this.onSync,
    required this.onRefresh,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: C.text)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              if (product.internalRef != null) _Meta('Ref: ${product.internalRef}'),
              if (product.sku != null) _Meta('SKU: ${product.sku}'),
              if (product.barcode != null) _Meta('Barcode: ${product.barcode}'),
            ],
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: _QtyBox(label: 'ERP On Hand', value: erp?.onHand, loading: loadingErp, color: C.accent)),
            const SizedBox(width: 10),
            Expanded(child: _QtyBox(label: 'Shaghlaty On Hand', value: shagh?.onHand, loading: loadingShagh, color: C.success)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _QtyBox(label: 'ERP Reserved', value: erp?.reserved, loading: loadingErp, color: C.accent, small: true)),
            const SizedBox(width: 10),
            Expanded(child: _QtyBox(label: 'Shaghlaty Reserved', value: shagh?.reserved, loading: loadingShagh, color: C.success, small: true)),
          ]),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: C.text),
                  decoration: const InputDecoration(labelText: 'Update Quantity', hintText: 'e.g. 42'),
                  onChanged: (_) => onActivity(),
                  onSubmitted: (_) => onSync(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: C.success),
                onPressed: syncing ? null : onSync,
                child: syncing ? const _Spinner() : const Text('Sync'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onRefresh, child: const Text('↻')),
            ],
          ),

          if (syncMsg != null) ...[
            const SizedBox(height: 12),
            StatusBar(msg: syncMsg!, type: syncType),
          ],
        ],
      ),
    );
  }
}

// ─── Draft Orders ─────────────────────────────────────────────────────────────

class _DraftOrders extends StatelessWidget {
  final bool loading;
  final List<SaleOrderLine>? orders;
  const _DraftOrders({required this.loading, this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders?.fold<double>(0, (s, o) => s + o.qty) ?? 0.0;
    final count = orders?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('DRAFT SALE ORDERS',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 1)),
            const Spacer(),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: C.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8CA6FF))),
              ),
          ]),
          const SizedBox(height: 12),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2, color: C.muted),
              ),
            )
          else if (orders == null || orders!.isEmpty)
            const Text('No draft sale orders for this product.',
                style: TextStyle(fontSize: 13, color: C.muted, fontStyle: FontStyle.italic))
          else ...[
            _OrderRow(name: 'Total', qty: '${fmtQty(total)} units', isTotal: true),
            const SizedBox(height: 6),
            ...orders!.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _OrderRow(name: o.orderName ?? '—', qty: '${fmtQty(o.qty)} units'),
                )),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String name, qty;
  final bool isTotal;
  const _OrderRow({required this.name, required this.qty, this.isTotal = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          color: isTotal ? C.warning.withOpacity(0.08) : C.surface2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: isTotal ? C.warning : C.border),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isTotal ? C.warning : C.text))),
            Text(qty,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: C.warning)),
          ],
        ),
      );
}

// ─── Qty Box ──────────────────────────────────────────────────────────────────

class _QtyBox extends StatelessWidget {
  final String label;
  final double? value;
  final bool loading, small;
  final Color color;

  const _QtyBox({
    required this.label,
    this.value,
    required this.loading,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: C.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 0.8),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            loading
                ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, color: C.muted))
                : Text(fmtQty(value),
                    style: TextStyle(
                        fontSize: small ? 22 : 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1),
                    textAlign: TextAlign.center),
          ],
        ),
      );
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class StatusBar extends StatelessWidget {
  final String msg, type;
  const StatusBar({super.key, required this.msg, required this.type});

  Color get _fg => switch (type) {
        'success' => const Color(0xFF5DE8A0),
        'error' => const Color(0xFFFF8A8A),
        'warning' => const Color(0xFFF5C26E),
        _ => const Color(0xFF8CA6FF),
      };
  Color get _base => switch (type) {
        'success' => C.success,
        'error' => C.danger,
        'warning' => C.warning,
        _ => C.accent,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _base.withOpacity(0.14),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _base.withOpacity(0.3)),
        ),
        child: Text(msg, style: TextStyle(fontSize: 13, color: _fg)),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
}

class _Meta extends StatelessWidget {
  final String text;
  const _Meta(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 12, color: C.muted));
}
