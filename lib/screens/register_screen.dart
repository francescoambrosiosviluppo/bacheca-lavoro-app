import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/common.dart';

/// Registrazione di una nuova azienda (R1).
/// Al termine torna al login restituendo l'email appena registrata.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final company = await context.read<AppState>().api.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(company.email);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione azienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Crea il tuo account', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Serve per pubblicare annunci e ricevere candidature.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome azienda', prefixIcon: Icon(Icons.business)),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Nome azienda'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'Almeno 6 caratteri',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.length < 6) ? 'La password deve avere almeno 6 caratteri' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              decoration: const InputDecoration(labelText: 'Conferma password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: (v) => v != _password.text ? 'Le password non coincidono' : null,
            ),
            const SizedBox(height: 28),
            BusyButton(busy: _busy, onPressed: _register, label: 'Crea account', icon: Icons.person_add),
          ],
        ),
      ),
    );
  }
}
