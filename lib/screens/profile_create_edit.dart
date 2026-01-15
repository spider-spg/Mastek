import 'package:flutter/material.dart';

class ProfileCreateEditScreen extends StatelessWidget {
  const ProfileCreateEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    String gender = 'Other';

    return Scaffold(
      appBar: AppBar(title: const Text('Create profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            DropdownButton<String>(
              value: gender,
              onChanged: (String? value) => gender = value ?? 'Other',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'Male', child: Text('Male')),
                DropdownMenuItem<String>(value: 'Female', child: Text('Female')),
                DropdownMenuItem<String>(value: 'Other', child: Text('Other')),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
