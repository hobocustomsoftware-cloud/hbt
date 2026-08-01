import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_button.dart';

/// Passenger self-service registration screen.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.auth.register(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join HBT',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account to book bus tickets.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Phone number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '09xxxxxxxxx',
                prefixText: '+95 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: validateMyanmarPhone,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: validatePassword,
            ),
            const SizedBox(height: 16),

            // First name
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name (optional)',
                border: OutlineInputBorder(),
              ),
              validator: validateOptionalName,
            ),
            const SizedBox(height: 16),

            // Last name
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name (optional)',
                border: OutlineInputBorder(),
              ),
              validator: validateOptionalName,
            ),
            const SizedBox(height: 24),

            // Error
            if (widget.auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.auth.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Register button
            BusyButton(
              label: 'Create Account',
              onPressed: widget.auth.loading ? null : _register,
              busy: widget.auth.loading,
            ),
            const SizedBox(height: 16),

            // Login link
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    ),
  );
}
