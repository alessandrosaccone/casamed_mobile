import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'profile_page.dart'; // Import the ProfilePage

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Controllers for healthcare expert fields
  final _addressController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _registrationController = TextEditingController();

  String message = '';
  String? selectedRole; // Variable to hold the selected role
  int? roleValue; // Will hold 0 or 1 based on the selection

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Replace with your API base URL
  }

  void register() async {
    try {
      final requestBody = {
        "email": _emailController.text,
        "pass": _passwordController.text,
        "role": roleValue, // Send the mapped role value (0 or 1)
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "birth_date": _birthDateController.text,
      };

      // Add the extra fields if the user is a Healthcare Expert (role 1)
      if (roleValue == 1) {
        requestBody.addAll({
          "address": _addressController.text,
          "vat_number": _vatNumberController.text,
          "professional_insurance_number": _insuranceNumberController.text,
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
        });
      }

      final response = await apiService.registerUser(requestBody);
      setState(() {
        message = 'Registration successful: ${response['message']}';
      });

      // Login automatically after successful registration
      await loginAfterRegistration();

    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  Future<void> loginAfterRegistration() async {
    try {
      final loginData = {
        "email": _emailController.text,
        "pass": _passwordController.text,
      };

      final loginResponse = await apiService.loginUser(loginData);

      // Check if login was successful
      if (loginResponse['success']) {
        // Save the token to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', loginResponse['token']);

        // Navigate to the profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: loginResponse['userId'], // Pass userId from login response
              token: loginResponse['token'],     // Pass the token
            ),
          ),
        );
      } else {
        setState(() {
          message = 'Login failed after registration: ${loginResponse['message']}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error during automatic login: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Use a scrollable view in case there are many fields
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)'),
              ),
              // Dropdown for role selection
              DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Select Role'),
                items: <String>['Patient', 'Healthcare Expert']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue;
                    roleValue = (newValue == 'Patient') ? 0 : 1; // Map to 0 or 1
                  });
                },
              ),

              // Show extra fields if "Healthcare Expert" is selected
              if (roleValue == 1) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _vatNumberController,
                  decoration: const InputDecoration(labelText: 'VAT Number'),
                ),
                TextField(
                  controller: _insuranceNumberController,
                  decoration: const InputDecoration(labelText: 'Professional Insurance Number'),
                ),
                TextField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
                TextField(
                  controller: _registrationController,
                  decoration: const InputDecoration(labelText: 'Professional Association Registration'),
                ),
              ],

              ElevatedButton(
                onPressed: selectedRole != null ? register : null, // Disable if role not selected
                child: const Text('Register'),
              ),
              Text(message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
