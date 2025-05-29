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
  Color messageColor = Colors.red; // Colore di default per i messaggi di errore
  String? selectedRole;
  int? roleValue;
  bool _isNurse = false;   // Nuova variabile per differenziare medico / infermiere
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

    if (_addressController.text.isEmpty) {
      setState(() {
        message = 'L\'indirizzo è obbligatorio.';
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
        "address": _addressController.text,
      };

      // Se roleValue == 1 (medico o infermiere), includiamo i campi aggiuntivi
      if (roleValue == 1) {
        requestBody.addAll({
          "vat_number": _vatNumberController.text,
          "professional_insurance_number": _insuranceNumberController.text,
          "professional_insurance_expiry_date": _expiryDateController.text,
          "iban": _ibanController.text,
          "professional_association_registration": _registrationController.text,
          // Aggiungiamo la chiave "is_nurse" in base a _isNurse
          "is_nurse": _isNurse
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

  // Costruzione dell'interfaccia
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
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Indirizzo'),
              ),

              // Dropdown ruoli
              DropdownButton<String>(
                value: selectedRole,
                hint: const Text('Seleziona il tuo ruolo'),
                items: <String>['Paziente', 'Medico', 'Infermiere'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRole = newValue;
                    if (newValue == 'Paziente') {
                      roleValue = 0;
                      _isNurse = false;
                    } else if (newValue == 'Medico') {
                      roleValue = 1;
                      _isNurse = false;
                    } else if (newValue == 'Infermiere') {
                      roleValue = 1;
                      _isNurse = true;
                    }
                  });
                },
              ),

              // Se il ruolo è 1 (medico o infermiere), mostra i campi aggiuntivi
              if (roleValue == 1) ...[
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
                    onChanged: _termsRead
                        ? (bool? value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    }
                        : null,
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


