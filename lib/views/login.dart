import 'package:flutter/material.dart';
import '../routes/routes.dart';
import '../services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login>{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _loading = true);
    var user = await AuthService().login(_emailController.text, _passwordController.text);
    setState(() => _loading = false);
    if(user != null){
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al iniciar sesión")));
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar( title: const Text("Login")),
      body: Padding (
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            _loading ? CircularProgressIndicator() :
            ElevatedButton(
              onPressed: _login,
              child: const Text("Login"),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}