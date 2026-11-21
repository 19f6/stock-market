import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _isSignUp = true;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    final u = _user.text.trim();
    final p = _pass.text;
    bloc.add(_isSignUp
        ? AuthSignUpRequested(u, p)
        : AuthLogInRequested(u, p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (a, b) => a.error != b.error && b.error != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.error!)));
              },
              builder: (context, state) {
                return Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.candlestick_chart, size: 56),
                      const SizedBox(height: 12),
                      Text('Mock Market',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Sign up and get ${money(AppConfig.startingBalance)} to trade'
                            : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _user,
                        decoration: const InputDecoration(labelText: 'Username'),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'At least 3 characters'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'At least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: state.submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16)),
                        child: state.submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isSignUp ? 'Create account' : 'Log in'),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp
                            ? 'I already have an account'
                            : 'Create a new account'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
