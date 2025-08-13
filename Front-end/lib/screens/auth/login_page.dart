import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // adjust if your file structure differs

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(_email.trim().toLowerCase(), _password);
      // On success, navigate to landing (token is stored)
      Navigator.pushReplacementNamed(context, '/landing');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String? _validateEmail(String? v) =>
      (v != null && v.contains('@')) ? null : 'Enter valid email';
  String? _validatePassword(String? v) =>
      (v != null && v.length >= 6) ? null : 'Min 6 chars';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                      onSaved: (v) => _email = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: _validatePassword,
                      onSaved: (v) => _password = v ?? '',
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                        onPressed: _login, child: const Text('Login')),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: const Text('Don\'t have an account? Sign up'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
