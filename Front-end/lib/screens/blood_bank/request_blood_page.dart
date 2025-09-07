import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart'; // <-- added

import '../../widgets/common_app_bar.dart';
import '../../config.dart';

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
  DateTime? _neededAt; // new field
  bool isSubmitting = false;
  String? errorMessage;

  final List<String> bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _pickNeededAt() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _neededAt ?? DateTime.now(),
      firstDate: DateTime.now(), // can't request for past
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _neededAt != null
          ? TimeOfDay(hour: _neededAt!.hour, minute: _neededAt!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _neededAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String? _formatNeededAtDisplay() {
    if (_neededAt == null) return null;
    return "${_neededAt!.day.toString().padLeft(2, '0')}/"
        "${_neededAt!.month.toString().padLeft(2, '0')}/"
        "${_neededAt!.year} "
        "${_neededAt!.hour.toString().padLeft(2, '0')}:"
        "${_neededAt!.minute.toString().padLeft(2, '0')}";
  }

  String? _isoNeededAt() {
    if (_neededAt == null) return null;
    // Format as YYYY-MM-DDTHH:MM:SS (no fractional seconds)
    final iso = _neededAt!.toIso8601String();
    return iso.split('.').first; // drop fraction and timezone
    // If you prefer local naive time, this is okay because backend expects no timezone.
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      setState(() {
        errorMessage = 'You must be logged in to submit a blood request.';
        isSubmitting = false;
      });
      return;
    }

    final payload = {
      "blood_group": bloodGroup,
      "amount": int.tryParse(amount) ?? 0,
      "location": location.trim(),
      "contact": contact.trim(),
      "note": note.trim().isEmpty ? null : note.trim(),
      if (_isoNeededAt() != null) "needed_at": _isoNeededAt(),
    };

    try {
      final url = Uri.parse('$baseUrl/blood_requests');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 201) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Request Submitted'),
            content: const Text('Your blood request has been submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    bloodGroup = null;
                    amount = '';
                    location = '';
                    contact = '';
                    note = '';
                    _neededAt = null;
                  });
                  _formKey.currentState?.reset();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (res.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthorized. Please log in again.';
        });
      } else {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        final msg = body is Map && body['msg'] != null ? body['msg'] : (res.reasonPhrase ?? 'Unknown error');
        setState(() {
          errorMessage = 'Error: $msg';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('Request Blood'),
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: bloodGroups
                    .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                    .toList(),
                value: bloodGroup,
                onChanged: (value) => setState(() => bloodGroup = value),
                validator: (value) => value == null ? 'Please select a blood group' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount Needed (in units)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => amount = value,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount needed';
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Amount must be a positive integer';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Patient/Hospital Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => location = value,
                validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              // CONTACT with 11-digit validation
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Contact Info',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 017XXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly, // digits only
                  LengthLimitingTextInputFormatter(11),   // cap at 11
                ],
                onChanged: (value) => contact = value,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Enter contact info';
                  if (!RegExp(r'^\d{11}$').hasMatch(v)) {
                    return 'Phone number must be exactly 11 digits';
                  }
                  // Optional Bangladesh rule:
                  // if (!RegExp(r'^01\d{9}$').hasMatch(v)) {
                  //   return 'BD numbers must start with 01';
                  // }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Blood Needed At'),
                subtitle: Text(_formatNeededAtDisplay() ?? 'Select date & time'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickNeededAt,
                ),
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
                onPressed: isSubmitting
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    submitRequest();
                  }
                },
                icon: isSubmitting
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit Request'),
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
