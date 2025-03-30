import 'package:flutter/material.dart';
import 'package:mess_ease/menu/menu.dart'; // Import the menu page
import 'package:cloud_firestore/cloud_firestore.dart'; // Import cloud_firestore

class SubscribedLoginPage extends StatefulWidget {
  const SubscribedLoginPage({super.key});

  @override
  State<SubscribedLoginPage> createState() => _SubscribedLoginPageState();
}

class _SubscribedLoginPageState extends State<SubscribedLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  String? selectedMessBlock;
  final List<String> messBlocks = [
    "Men's: K-block paid",
    "Men's: L-block paid",
    "Men's: Q-block paid",
    "Men's: H-block paid",
    "Women's: K-block paid",
    "Women's: L-block paid",
    "Women's: Q-block paid",
    "Women's: H-block paid",
  ];

  bool validateRegNo(String regNo) {
    return RegExp(r'^[0-9]{2}[A-Z]{3}[0-9]{4}$').hasMatch(regNo);
  }

  bool validateEmail(String email) {
    return RegExp(r'^[a-z]+(\.[a-z]+)?[0-9]{4}@vitstudent\.ac\.in$').hasMatch(email);
  }

  Future<String?> getUserId(String regNo) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('regNo', isEqualTo: regNo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        return null; // Return null if no matching user is found
      }
    } catch (e) {
      print('Error getting user ID: $e');
      return null; // Return null on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribed Student Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter your name' : null,
              ),
              TextFormField(
                controller: regNoController,
                decoration: const InputDecoration(labelText: 'Registration Number'),
                validator: (value) =>
                    (value == null || value.isEmpty || !validateRegNo(value))
                        ? 'Enter a valid registration number (DDLLLDDDD)'
                        : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    (value == null || value.isEmpty || !validateEmail(value))
                        ? 'Enter a valid VIT email (name.lastnameyear@vitstudent.ac.in)'
                        : null,
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: '4-Digit Code'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    (value == null || value.length != 4 || int.tryParse(value) == null)
                        ? 'Enter a valid 4-digit code'
                        : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Mess Block'),
                value: selectedMessBlock,
                items: messBlocks.map((block) {
                  return DropdownMenuItem<String>(
                    value: block,
                    child: Text(block),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedMessBlock = newValue;
                  });
                },
                validator: (value) => (value == null) ? 'Please select a mess block' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? userId = await getUserId(regNoController.text);
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuPage(
                            isSubscribed: true,
                            userId: userId, // Pass the userId
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not found.')),
                      );
                    }
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}