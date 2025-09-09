import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/common_app_bar.dart';

import '../../config.dart';

class RegisterDonorPage extends StatefulWidget {
  const RegisterDonorPage({super.key});

  @override
  State<RegisterDonorPage> createState() => _RegisterDonorPageState();
}

class _RegisterDonorPageState extends State<RegisterDonorPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  String? _bloodGroup;
  DateTime? _lastDonationDate;
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];


  // Secure storage to get stored JWT token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastDonationDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      _showError('You must be logged in to register as a donor.');
      return;
    }

    final donorData = {
      "name": _nameController.text.trim(),
      "blood_group": _bloodGroup,
      "last_donation_date": _lastDonationDate != null
          ? _lastDonationDate!.toIso8601String().split('T')[0]
          : null,
      "address": _addressController.text.trim(),
      "contact": _contactController.text.trim(),
    };

    try {
      final url = Uri.parse('${Config.baseUrl}/donors');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // <-- Add token here
        },
        body: jsonEncode(donorData),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Donor information submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _nameController.clear();
                    _bloodGroup = null;
                    _lastDonationDate = null;
                    _addressController.clear();
                    _contactController.clear();
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final errorMsg = jsonDecode(response.body)['msg'] ?? 'Unknown error';
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('Failed to submit. Please check your connection.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Register as Donor'),
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  border: OutlineInputBorder(),
                ),
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) => setState(() => _bloodGroup = value),
                value: _bloodGroup,
                validator: (value) =>
                    value == null ? "Please select a blood group" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Last Donation Date"),
                subtitle: Text(
                  _lastDonationDate == null
                      ? "Select date"
                      : "${_lastDonationDate!.day}/${_lastDonationDate!.month}/${_lastDonationDate!.year}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Enter contact number"
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.person_add),
                label: const Text("Register"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
