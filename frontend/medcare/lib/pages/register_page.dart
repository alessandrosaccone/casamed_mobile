/*import 'package:flutter/material.dart';
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
  final _expiryDateController = TextEditingController(); // New controller for expiry date
  final _ibanController = TextEditingController();
  final _registrationController = TextEditingController();

  String message = '';
  String? selectedRole;
  int? roleValue;
  late ApiService apiService;

  bool _termsAccepted = false; // Variable for accepting terms
  bool _termsRead = false; // Variable to track if the user has read the terms

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Replace with your API base URL
  }

  void register() async {
    if (!_termsAccepted) {
      setState(() {
        message = 'You must accept the terms and conditions.';
      });
      return;
    }

    try {
      final requestBody = {
        "email": _emailController.text,
        "pass": _passwordController.text,
        "role": roleValue,
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "birth_date": _birthDateController.text,
      };

      if (roleValue == 1) {
        requestBody.addAll({
          "address": _addressController.text,
          "vat_number": _vatNumberController.text,
          "professional_insurance_number": _insuranceNumberController.text,
          "professional_insurance_expiry_date": _expiryDateController.text, // Add expiry date
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
        });
      }

      final response = await apiService.registerUser(requestBody);
      setState(() {
        message = 'Registrazione riuscita: ${response['message']}';
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

      if (loginResponse['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', loginResponse['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: loginResponse['userId'],
              token: loginResponse['token'],
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

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termini e Condizioni'),
          content: SizedBox(
            height: 300.0,
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  Text('''Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'''),
                  // Add more placeholder text to simulate long terms and conditions
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ho capito'),
              onPressed: () {
                setState(() {
                  _termsRead = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
              ),
              TextField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: 'Data di nascita (GG-MM-AAAA)'),
              ),
              DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Seleziona il tuo ruolo'),
                items: <String>['Paziente', 'Medico'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue;
                    roleValue = (newValue == 'Paziente') ? 0 : 1;
                  });
                },
              ),
              if (roleValue == 1) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Indirizzo'),
                ),
                TextField(
                  controller: _vatNumberController,
                  decoration: const InputDecoration(labelText: 'Partita IVA'),
                ),
                TextField(
                  controller: _insuranceNumberController,
                  decoration: const InputDecoration(labelText: 'Numero Assicurazione'),
                ),
                TextField(
                  controller: _expiryDateController, // New TextField for expiry date
                  decoration: const InputDecoration(labelText: 'Data di scadenza dell\'assicurazione (GG-MM-AAAA)'),
                ),
                TextField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
                TextField(
                  controller: _registrationController,
                  decoration: const InputDecoration(labelText: 'Iscrizione all\'Ordine'),
                ),
              ],
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: _termsRead ? (bool? value) {
                      setState(() {
                        _termsAccepted = value!;
                      });
                    } : null,
                  ),
                  GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: const Text(
                      'Accetta Termini e Condizioni',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedRole != null && _termsAccepted ? register : null,
                child: const Text('Registrati'),
              ),
              Text(message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}*/







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
  final _expiryDateController = TextEditingController(); // New controller for expiry date
  final _ibanController = TextEditingController();
  final _registrationController = TextEditingController();

  String message = '';
  String? selectedRole;
  int? roleValue;
  late ApiService apiService;

  bool _termsAccepted = false; // Variable for accepting terms
  bool _termsRead = false; // Variable to track if the user has read the terms

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Replace with your API base URL
  }

  void register() async {
    if (!_termsAccepted) {
      setState(() {
        message = 'You must accept the terms and conditions.';
      });
      return;
    }

    try {
      final requestBody = {
        "email": _emailController.text,
        "pass": _passwordController.text,
        "role": roleValue,
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "birth_date": _birthDateController.text,
      };

      if (roleValue == 1) {
        requestBody.addAll({
          "address": _addressController.text,
          "vat_number": _vatNumberController.text,
          "professional_insurance_number": _insuranceNumberController.text,
          "professional_insurance_expiry_date": _expiryDateController.text, // Add expiry date
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
        });
      }

      final response = await apiService.registerUser(requestBody);
      setState(() {
        message = 'Registrazione riuscita: ${response['message']}';
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

      if (loginResponse['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', loginResponse['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: loginResponse['userId'],
              token: loginResponse['token'],
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

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termini e Condizioni'),
          content: SizedBox(
            height: 300.0,
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  Text('''Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'''),
                  // Add more placeholder text to simulate long terms and conditions
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ho capito'),
              onPressed: () {
                setState(() {
                  _termsRead = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
              ),
            TextField(
              controller: _birthDateController,
              decoration: const InputDecoration(labelText: 'Data di nascita (YYYY-MM-DD)'),
              readOnly: true, // Rende il campo non modificabile manualmente
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900), // Imposta una data minima
                  lastDate: DateTime(2100),  // Imposta una data massima
                );
                if (pickedDate != null) {
                  setState(() {
                    // Formatta la data in YYYY-MM-DD e la imposta nel controller
                    _birthDateController.text = pickedDate.toIso8601String().split('T').first;
                  });
                }
              },
            ),

              DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Seleziona il tuo ruolo'),
                items: <String>['Paziente', 'Medico'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue;
                    roleValue = (newValue == 'Paziente') ? 0 : 1;
                  });
                },
              ),
              if (roleValue == 1) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Indirizzo'),
                ),
                TextField(
                  controller: _vatNumberController,
                  decoration: const InputDecoration(labelText: 'Partita IVA'),
                ),
                TextField(
                  controller: _insuranceNumberController,
                  decoration: const InputDecoration(labelText: 'Numero Assicurazione'),
                ),
                TextField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(labelText: 'Data di scadenza dell\'assicurazione (YYYY-MM-DD)'),
                  readOnly: true, // Rende il campo non modificabile manualmente
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900), // Imposta una data minima
                      lastDate: DateTime(2100),  // Imposta una data massima
                    );
                    if (pickedDate != null) {
                      setState(() {
                        // Formatta la data in YYYY-MM-DD e la imposta nel controller
                        _expiryDateController.text = pickedDate.toIso8601String().split('T').first;
                      });
                    }
                  },
                ),

                TextField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
                TextField(
                  controller: _registrationController,
                  decoration: const InputDecoration(labelText: 'Iscrizione all\'Ordine'),
                ),
              ],
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: _termsRead ? (bool? value) {
                      setState(() {
                        _termsAccepted = value!;
                      });
                    } : null,
                  ),
                  GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: const Text(
                      'Accetta Termini e Condizioni',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedRole != null && _termsAccepted ? register : null,
                child: const Text('Registrati'),
              ),
              Text(message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}










/*import 'package:flutter/material.dart';
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
  String? selectedRole;
  int? roleValue;
  late ApiService apiService;

  bool _termsAccepted = false; // Variable for accepting terms
  bool _termsRead = false; // Variable to track if the user has read the terms

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Replace with your API base URL
  }

  void register() async {
    if (!_termsAccepted) {
      setState(() {
        message = 'You must accept the terms and conditions.';
      });
      return;
    }

    try {
      final requestBody = {
        "email": _emailController.text,
        "pass": _passwordController.text,
        "role": roleValue,
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "birth_date": _birthDateController.text,
      };

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
        message = 'Registrazione riuscita: ${response['message']}';
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

      if (loginResponse['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', loginResponse['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: loginResponse['userId'],
              token: loginResponse['token'],
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

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termini e Condizioni'),
          content: SizedBox(
            height: 300.0,
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  Text('''Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'''),
                  // Add more placeholder text to simulate long terms and conditions
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ho capito'),
              onPressed: () {
                setState(() {
                  _termsRead = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
              ),
              TextField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: 'Data di nascita (YYYY-MM-DD)'),
              ),
              DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Seleziona il tuo ruolo'),
                items: <String>['Paziente', 'Medico'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue;
                    roleValue = (newValue == 'Paziente') ? 0 : 1;
                  });
                },
              ),
              if (roleValue == 1) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Indirizzo'),
                ),
                TextField(
                  controller: _vatNumberController,
                  decoration: const InputDecoration(labelText: 'Partita IVA'),
                ),
                TextField(
                  controller: _insuranceNumberController,
                  decoration: const InputDecoration(labelText: 'Numero Assicurazione'),
                ),
                TextField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
                TextField(
                  controller: _registrationController,
                  decoration: const InputDecoration(labelText: 'Iscrizione all\'Ordine'),
                ),
              ],
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: _termsRead ? (bool? value) {
                      setState(() {
                        _termsAccepted = value!;
                      });
                    } : null,
                  ),
                  GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: const Text(
                      'Accetta Termini e Condizioni',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedRole != null && _termsAccepted ? register : null,
                child: const Text('Registrati'),
              ),
              Text(message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}*/
