import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final bool embedded;
  const LoginPage({super.key, this.embedded = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login({required bool register}) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (register) {
        await AuthService.register(
          emailCtrl.text.trim(),
          passCtrl.text.trim(),
        );
      } else {
        await AuthService.signIn(
          emailCtrl.text.trim(),
          passCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          error = 'Этот email уже зарегистрирован';
        } else if (e.code == 'wrong-password') {
          error = 'Неверный пароль';
        } else if (e.code == 'user-not-found') {
          error = 'Пользователь не найден';
        } else if (e.code == 'weak-password') {
          error = 'Пароль слишком простой';
        } else {
          error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
        ? null
        : AppBar(title: const Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 8),

            if (loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: () => _login(register: false),
                child: const Text("Войти"),
              ),
              TextButton(
                onPressed: () => _login(register: true),
                child: const Text("Регистрация"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
