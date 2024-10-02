import 'package:flutter/material.dart';
import 'dart:convert'; // Per convertire la risposta JSON
import 'package:http/http.dart' as http; // Pacchetto HTTP per fare richieste

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Counter App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // Variabile per tenere traccia del contatore
  String message = 'Waiting for response...'; // Messaggio di attesa

  // Funzione per fare la richiesta GET per ottenere il contatore
  Future<void> fetchCounter() async {
    final url = Uri.parse('http://10.0.2.2:3000/counter'); // Usa 10.0.2.2 per localhost in Android Emulator
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _counter = data['counter']; // Estrai il contatore dalla risposta JSON
        });
      } else {
        setState(() {
          message = 'Error: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        message = 'Failed to connect: $error';
      });
    }
  }

  // Funzione per fare la richiesta POST per incrementare il contatore
  Future<void> incrementCounter() async {
    final url = Uri.parse('http://10.0.2.2:3000/increment'); // Usa 10.0.2.2 per localhost in Android Emulator
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _counter = data['counter']; // Aggiorna il contatore
        });
      } else {
        setState(() {
          message = 'Error: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        message = 'Failed to connect: $error';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCounter(); // Esegui la richiesta GET quando l'app si avvia
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current Count:',
            ),
            Text(
              '$_counter', // Mostra il contatore
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: incrementCounter, // Incrementa il contatore al clic
              child: const Text('Increment Counter'),
            ),
            Text(
              message,
              style: const TextStyle(color: Colors.red), // Mostra messaggi di errore
            ),
          ],
        ),
      ),
    );
  }
}
