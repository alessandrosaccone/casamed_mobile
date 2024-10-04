// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String token;

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ApiService apiService;
  Map<String, dynamic>? userProfile;
  String message = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    String token = widget.token;
    int userId = widget.userId;

    if (token.isNotEmpty) {
      try {
        final profileData = await apiService.getUserProfile(userId, token);
        setState(() {
          userProfile = profileData;
        });
      } catch (e) {
        setState(() {
          message = 'Failed to load user profile: $e';
        });
      }
    } else {
      setState(() {
        message = 'No token found, please login again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: userProfile == null
            ? Text(message)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User ID: ${userProfile!['userData']['id']}'),
            Text('Email: ${userProfile!['userData']['email']}'),
            Text('First Name: ${userProfile!['userData']['first_name'] ??
                'N/A'}'),
            Text(
                'Last Name: ${userProfile!['userData']['last_name'] ?? 'N/A'}'),

            // Visualizza i dati aggiuntivi se non sono nulli
            ..._buildAdditionalFields(userProfile!['userData']),
          ],
        ),
      ),
    );
  }

// Helper method to build additional fields if they are not null
  List<Widget> _buildAdditionalFields(Map<String, dynamic> userData) {
    List<Widget> fields = [];

    if (userData['birth_date'] != null) {
      fields.add(Text('Birth Date: ${userData['birth_date']}'));
    }

    if (userData['address'] != null) {
      fields.add(Text('Address: ${userData['address']}'));
    }

    if (userData['vat_number'] != null) {
      fields.add(Text('VAT Number: ${userData['vat_number']}'));
    }

    if (userData['professional_insurance_number'] != null) {
      fields.add(Text(
          'Professional Insurance Number: ${userData['professional_insurance_number']}'));
    }

    if (userData['iban'] != null) {
      fields.add(Text('IBAN: ${userData['iban']}'));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(Text(
          'Professional Association Registration: ${userData['professional_association_registration']}'));
    }

    return fields; // Returns the list of non-null widgets
  }
}