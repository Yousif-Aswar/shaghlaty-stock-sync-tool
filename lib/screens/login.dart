import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  final bool sessionExpired;
  const LoginScreen({super.key, this.sessionExpired = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      _error = 'Session expired. Please sign in again.';
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await Api.instance.login(u, p);
      Api.instance.setToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(username: u)),
      );
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Stock Sync',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: C.text),
                  ),
                  const SizedBox(height: 6),
                  const Text('Sign in to continue',
                      style: TextStyle(fontSize: 13, color: C.muted)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _userCtrl,
                    style: const TextStyle(color: C.text),
                    decoration: const InputDecoration(labelText: 'Username'),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    onSubmitted: (_) => _passFocus.requestFocus(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    focusNode: _passFocus,
                    style: const TextStyle(color: C.text),
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: C.muted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _StatusBanner(msg: _error!, type: 'error'),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String msg, type;
  const _StatusBanner({required this.msg, required this.type});

  Color get _fg => switch (type) {
        'success' => const Color(0xFF5DE8A0),
        'error' => const Color(0xFFFF8A8A),
        'warning' => const Color(0xFFF5C26E),
        _ => const Color(0xFF8CA6FF),
      };
  Color get _bg => switch (type) {
        'success' => C.success,
        'error' => C.danger,
        'warning' => C.warning,
        _ => C.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _bg.withOpacity(0.3)),
      ),
      child: Text(msg, style: TextStyle(fontSize: 13, color: _fg)),
    );
  }
}
