import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginSignUpPage extends StatefulWidget {
  const LoginSignUpPage({super.key});

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _toggleMode() => setState(() => isLogin = !isLogin);

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (isLogin) {
          // LOGIN FLOW
          await _authService.signInWithPhoneAndPassword(
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          );

          final uid = _authService.getCurrentUser()?.uid;
          final fcmToken = await FirebaseMessaging.instance.getToken();

          if (uid != null && fcmToken != null) {
            await _authService.updateUserToken(uid: uid, token: fcmToken);
          }
        } else {
          // SIGN UP FLOW
          await _authService.registerUser(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            firstName: _firstNameController.text.trim(),
            surname: _surnameController.text.trim(),
            phone: _phoneController.text.trim(),
            token: '',
            // Token is handled inside registerUser()
          );
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLogin
                    ? "Logged in successfully"
                    : "Account created successfully",
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Login" : "Sign Up"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                isLogin ? "Welcome back" : "Create your account",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin) ...[
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: "First Name *",
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _surnameController,
                        decoration: const InputDecoration(
                          labelText: "Surname *",
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email *"),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone Number *",
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password *",
                      ),
                      validator:
                          (val) => val!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(isLogin ? "Login" : "Sign Up"),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(
                        isLogin
                            ? "New to TapAlert? Sign up"
                            : "Already have an account? Login",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
