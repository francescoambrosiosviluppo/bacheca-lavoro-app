import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/common.dart';
import 'company_home_screen.dart';
import 'register_screen.dart';

/// Login dell'azienda (R2).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<AppState>().login(_email.text.trim(), _password.text);
      if (!mounted) return;
      // Sostituisce il login con l'area riservata.
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CompanyHomeScreen()));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goToRegister() async {
    final email = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (email != null && mounted) {
      _email.text = email;
      _password.clear();
      showSnack(context, 'Account creato! Ora accedi con le tue credenziali.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Area aziende')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.business, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Accedi', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Pubblica annunci e consulta le candidature ricevute.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.isEmpty) ? 'Password obbligatoria' : null,
            ),
            const SizedBox(height: 24),
            BusyButton(busy: _busy, onPressed: _login, label: 'Accedi', icon: Icons.login),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Non hai un account?'),
                TextButton(onPressed: _busy ? null : _goToRegister, child: const Text('Registrati')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
