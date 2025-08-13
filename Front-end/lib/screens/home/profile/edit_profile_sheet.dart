import 'package:flutter/material.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => EditProfileSheetState();
}

class EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  String email = "fahim.deesun@mist.ac.bd";
  String phone = "+8801XXXXXXXXX";
  String hometown = "Dhaka, Bangladesh";
  String imagePath = "assets/profile.png";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: AssetImage(imagePath),
                  ),
                  Positioned(
                    child: InkWell(
                      onTap: () {
                        // Placeholder for image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Image picker coming soon!"),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.contains('@')
                    ? null
                    : "Enter a valid email",
                onSaved: (val) => email = val ?? email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val != null && val.length >= 11
                    ? null
                    : "Enter a valid phone",
                onSaved: (val) => phone = val ?? phone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: hometown,
                decoration: const InputDecoration(
                  labelText: "Hometown / Address",
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => hometown = val ?? hometown,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile updated!")),
                      );
                    }
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
