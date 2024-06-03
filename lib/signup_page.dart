import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:cengproject/dbhelper/mongodb.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username and password cannot be empty';
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _errorMessage = '';
        });
      });

      return;
    }

    bool isCreated = await MongoDatabase.createUser(username, password);

    setState(() {
      _isLoading = false;
    });

    if (isCreated) {
      // Navigate to LoginPage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      setState(() {
        _errorMessage = 'Username already exists';
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _errorMessage = '';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
=======
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _page(),
        ),
>>>>>>> main
      ),
      backgroundColor: const Color.fromARGB(255, 34, 43, 170),
      body: _page(),
    );
  }

  Widget _page() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _inputField("Username", usernameController),
              const SizedBox(height: 20),
              _inputField("Password", passwordController, isPassword: true),
<<<<<<< HEAD
              const SizedBox(height: 30),
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorMessage.isNotEmpty)
=======
              const SizedBox(height: 10),
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorMessage.isNotEmpty) ...[
>>>>>>> main
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 30),
              _signupBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hintText, TextEditingController controller,
      {bool isPassword = false}) {
    var border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white, width: 2),
    );

    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      obscureText: isPassword,
    );
  }

  Widget _signupBtn() {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
<<<<<<< HEAD
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 18, 170, 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
=======
        foregroundColor: Colors.grey,
        backgroundColor: Colors.white,
        shape: const StadiumBorder(),
>>>>>>> main
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "Sign Up",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
