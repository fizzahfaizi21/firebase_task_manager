import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final Function toggleView;

  const SignupScreen({Key? key, required this.toggleView}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up to Task Manager'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
            onPressed: () => widget.toggleView(),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => loading = true);
                          try {
                            dynamic result = await _auth
                                .registerWithEmailAndPassword(email, password);
                            if (result == null) {
                              setState(() {
                                error = 'Please supply a valid email';
                                loading = false;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              if (e
                                  .toString()
                                  .contains('email-already-in-use')) {
                                error = 'This email is already registered';
                              } else if (e
                                  .toString()
                                  .contains('invalid-email')) {
                                error = 'Please enter a valid email format';
                              } else if (e
                                  .toString()
                                  .contains('weak-password')) {
                                error = 'Password is too weak';
                              } else {
                                error = 'Registration failed: ${e.toString()}';
                              }
                              loading = false;
                            });
                          }
                        }
                      },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
              const SizedBox(height: 12.0),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}
