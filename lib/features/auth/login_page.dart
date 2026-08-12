import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../widgets/brand_logo.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
    final err = ref.read(authControllerProvider).error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login gagal. Periksa email & password.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface, cs.surfaceContainer],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  const SizedBox(height: 40),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                    ),
                    child: const BrandLogo(size: 84),
                  ),
                  const SizedBox(height: 20),
                  Text(kBrandName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(kBrandTagline, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 40),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email tidak valid'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Minimal 6 karakter'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Masuk'),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
