import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'sync_screen.dart' show StatusBar;
import 'login.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  int _page = 1;
  SyncLogPage? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Api.instance.getSyncLogs(page: page);
      if (mounted) setState(() { _data = result; _page = page; });
    } on SessionExpiredException {
      if (!mounted) return;
      Api.instance.clearToken();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const LoginScreen(sessionExpired: true)),
        (_) => false,
      );
    } on Exception catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar
        Container(
          padding:
              const EdgeInsets.fromLTRB(16, 14, 12, 14),
          color: C.surface,
          child: Row(
            children: [
              const Text('Audit Log',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: C.text)),
              if (_data != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: C.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${_data!.total}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8CA6FF))),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: C.muted, size: 20),
                onPressed: _loading ? null : () => _load(_page),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: C.border),

        // Content
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: C.accent))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: StatusBar(msg: _error!, type: 'error'),
                      ),
                    )
                  : _data == null || _data!.results.isEmpty
                      ? const Center(
                          child: Text('No audit entries.',
                              style:
                                  TextStyle(color: C.muted, fontSize: 14)))
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          itemCount: _data!.results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _LogCard(log: _data!.results[i]),
                        ),
        ),

        // Pagination
        if (_data != null && _data!.numPages > 1)
          _Pagination(
            current: _page,
            total: _data!.numPages,
            hasPrev: _page > 1,
            hasNext: _data!.nextPage != null,
            onPrev: () => _load(_page - 1),
            onNext: () => _load(_page + 1),
          ),
      ],
    );
  }
}

// ─── Log Card ─────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final SyncLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final bothOk = log.erpSuccess && log.shaghSuccess;
    final partial = log.erpSuccess != log.shaghSuccess;
    final statusColor =
        bothOk ? C.success : (partial ? C.warning : C.danger);
    final statusLabel =
        bothOk ? 'Success' : (partial ? 'Partial' : 'Failed');

    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Internal ref + barcode
          if (log.internalRef != null || log.barcode != null) ...[
            Row(
              children: [
                if (log.internalRef != null)
                  Text(log.internalRef!,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.text)),
                if (log.internalRef != null && log.barcode != null)
                  const SizedBox(width: 10),
                if (log.barcode != null)
                  Text(log.barcode!,
                      style: const TextStyle(fontSize: 12, color: C.muted)),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Top row: date + user + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.formattedDate,
                        style:
                            const TextStyle(fontSize: 11, color: C.muted)),
                    if (log.performedBy != null) ...[
                      const SizedBox(height: 2),
                      Text(log.performedBy!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: C.text)),
                    ],
                  ],
                ),
              ),
              _StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),

          // Target qty
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: C.muted),
              children: [
                const TextSpan(text: 'Target  '),
                TextSpan(
                  text: fmtQty(log.targetQty),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: C.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ERP + Shaghlaty columns
          Row(children: [
            Expanded(
                child: _ChangeBox(
                    label: 'ERP',
                    before: log.erpBefore,
                    after: log.erpAfter,
                    ok: log.erpSuccess)),
            const SizedBox(width: 10),
            Expanded(
                child: _ChangeBox(
                    label: 'Shaghlaty',
                    before: log.shaghBefore,
                    after: log.shaghAfter,
                    ok: log.shaghSuccess,
                    delta: log.shaghDelta)),
          ]),

          if (log.errorDetail != null &&
              log.errorDetail!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.errorDetail!,
                style:
                    const TextStyle(fontSize: 11, color: C.danger)),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _ChangeBox extends StatelessWidget {
  final String label;
  final double? before, after, delta;
  final bool ok;

  const _ChangeBox(
      {required this.label,
      this.before,
      this.after,
      required this.ok,
      this.delta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.muted,
                    letterSpacing: 0.5)),
            const Spacer(),
            Icon(
              ok ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 14,
              color: ok ? C.success : C.danger,
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text(fmtQty(before),
                style:
                    const TextStyle(fontSize: 13, color: C.muted)),
            const Text('  →  ',
                style: TextStyle(fontSize: 12, color: C.muted)),
            Text(fmtQty(after),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: C.text)),
            if (delta != null) ...[
              const Spacer(),
              Text('Δ${fmtQty(delta)}',
                  style: const TextStyle(
                      fontSize: 11, color: C.warning)),
            ],
          ]),
        ],
      ),
    );
  }
}

// ─── Pagination bar ───────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  final int current, total;
  final bool hasPrev, hasNext;
  final VoidCallback onPrev, onNext;

  const _Pagination({
    required this.current,
    required this.total,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: hasPrev ? C.accent : C.muted,
            onPressed: hasPrev ? onPrev : null,
          ),
          Text('Page $current of $total',
              style: const TextStyle(color: C.muted, fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: hasNext ? C.accent : C.muted,
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
