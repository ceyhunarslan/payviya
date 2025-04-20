import 'package:flutter/material.dart';
import 'package:payviya_app/services/auth_service.dart';

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({Key? key}) : super(key: key);

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  String _status = "Ready to test";
  final _emailController = TextEditingController(text: "user@example.com");
  final _passwordController = TextEditingController(text: "password");

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _status = "Testing login with: ${_emailController.text} / ${_passwordController.text}";
    });

    try {
      final user = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _status = "Login successful! User: ${user.name} (${user.email})";
      });
    } catch (e) {
      setState(() {
        _status = "Login failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testLogin,
              child: const Text("Test Login"),
            ),
          ],
        ),
      ),
    );
  }
} 