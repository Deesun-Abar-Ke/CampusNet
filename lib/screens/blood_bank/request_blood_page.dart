import 'package:flutter/material.dart';

class RequestBloodPage extends StatefulWidget {
  const RequestBloodPage({super.key});

  @override
  State<RequestBloodPage> createState() => _RequestBloodPageState();
}

class _RequestBloodPageState extends State<RequestBloodPage> {
  final _formKey = GlobalKey<FormState>();
  String? bloodGroup;
  String amount = '';
  String location = '';
  String contact = '';
  String note = '';

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🙋 Request Blood'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: bloodGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) => setState(() => bloodGroup = value),
                validator: (value) =>
                value == null ? 'Please select a blood group' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount Needed (in units)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => amount = value,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter amount needed' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Patient/Hospital Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => location = value,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Contact Info',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => contact = value,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter contact info' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Additional Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => note = value,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // For now, just show confirmation
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Request Submitted'),
                        content: const Text('Your blood request has been submitted.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Request'),
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
