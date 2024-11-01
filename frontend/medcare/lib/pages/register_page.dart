import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'home_page.dart'; // Importa la pagina home

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

  // Controllers per i campi dell'operatore sanitario
  final _addressController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _ibanController = TextEditingController();
  final _registrationController = TextEditingController();

  String message = '';
  Color messageColor = Colors.red; // Colore di default per messaggi di errore
  String? selectedRole;
  int? roleValue;
  late ApiService apiService;

  bool _termsAccepted = false;
  bool _termsRead = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Sostituisci con il tuo URL di base
  }

  void register() async {
    if (!_termsAccepted) {
      setState(() {
        message = 'Devi accettare i termini e le condizioni.';
        messageColor = Colors.red; // Colore per errore
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
          "professional_insurance_expiry_date": _expiryDateController.text,
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
        });
      }

      final response = await apiService.registerUser(requestBody);
      setState(() {
        if (response['success']) {
          message = 'Registrazione riuscita. Controlla la tua email per verificare il tuo account ed effettua il Login.';
          messageColor = Colors.green; // Colore per successi

          // Naviga alla pagina home dopo la registrazione
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Reindirizzamento alla Home Page
          );
        } else {
          message = 'Errore durante la registrazione: ${response['message']}';
          messageColor = Colors.red; // Colore per errore
        }
      });
    } catch (e) {
      setState(() {
        message = 'Errore: $e';
        messageColor = Colors.red; // Colore per errore
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
                  Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'),
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
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
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
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
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
              Text(message, style: TextStyle(color: messageColor)),
            ],
          ),
        ),
      ),
    );
  }
}









/*import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';

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
  final _expiryDateController = TextEditingController();
  final _ibanController = TextEditingController();
  final _registrationController = TextEditingController();

  String message = '';
  Color messageColor = Colors.red; // Default message color set to red for errors
  String? selectedRole;
  int? roleValue;
  late ApiService apiService;

  bool _termsAccepted = false;
  bool _termsRead = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Replace with your API base URL
  }

  void register() async {
    if (!_termsAccepted) {
      setState(() {
        message = 'You must accept the terms and conditions.';
        messageColor = Colors.red; // Error color
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
          "professional_insurance_expiry_date": _expiryDateController.text,
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
        });
      }

      final response = await apiService.registerUser(requestBody);
      setState(() {
        if (response['success']) {
          message = 'Registrazione riuscita. Controlla la tua email per verificare il tuo account ed effettua il Login.';
          messageColor = Colors.green; // Success color
        } else {
          message = 'Errore durante la registrazione: ${response['message']}';
          messageColor = Colors.red; // Error color
        }
      });
    } catch (e) {
      setState(() {
        message = 'Errore: $e';
        messageColor = Colors.red; // Error color
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
          message = 'Login fallito dopo la registrazione: ${loginResponse['message']}';
          messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Errore durante il login automatico: $e';
        messageColor = Colors.red;
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
                  Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...'),
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
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
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
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
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
              Text(message, style: TextStyle(color: messageColor)),
            ],
          ),
        ),
      ),
    );
  }
}*/