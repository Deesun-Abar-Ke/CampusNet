import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // adjust path if needed

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String? _phone;
  String? _designation;
  bool _loading = false;
  String? _error;

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.signup(
        name: _name,
        email: _email,
        password: _password,
        phone: _phone,
        designation: _designation,
      );
      // On success, navigate to landing (you now have stored token)
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
  String? _validateName(String? v) =>
      (v != null && v.trim().isNotEmpty) ? null : 'Name required';

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
                    const Text('Sign Up',
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
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: _validateName,
                      onSaved: (v) => _name = v!.trim(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                      onSaved: (v) => _email = v!.trim().toLowerCase(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: _validatePassword,
                      onSaved: (v) => _password = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                      onSaved: (v) => _phone = v?.trim(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Designation (optional)',
                      ),
                      onSaved: (v) => _designation = v?.trim(),
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                        onPressed: _signup, child: const Text('Sign Up')),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Already have an account? Login'),
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
