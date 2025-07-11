import 'package:flutter/material.dart';

class RegisterDonorPage extends StatefulWidget {
  const RegisterDonorPage({super.key});

  @override
  State<RegisterDonorPage> createState() => _RegisterDonorPageState();
}

class _RegisterDonorPageState extends State<RegisterDonorPage> {
  final _formKey = GlobalKey<FormState>();
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // You can handle submission logic here
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text('Donor information submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🩸 Register as Donor"),
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
                  labelText: "Blood Group",
                  border: OutlineInputBorder(),
                ),
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(
                  value: bg,
                  child: Text(bg),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _bloodGroup = value),
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
                validator: (value) =>
                value == null || value.isEmpty ? "Enter contact number" : null,
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
