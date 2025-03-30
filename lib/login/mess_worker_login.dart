import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_ease/dashboard/mess_worker_dashboard.dart';

class MessWorkerLoginPage extends StatefulWidget {
  const MessWorkerLoginPage({super.key});

  @override
  State<MessWorkerLoginPage> createState() => _MessWorkerLoginPageState();
}

class _MessWorkerLoginPageState extends State<MessWorkerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  String? selectedMessBlock;
  final List<String> messBlocks = ['K-block', 'L-block', 'Q-block', 'H-block'];
  final List<String> genderSides = ["Men's", "Women's"];
  String? selectedGender;

  void saveWorkerData() async {
    final String empId = employeeIdController.text.trim();

    final workerRef = FirebaseFirestore.instance.collection('mess_workers').doc(empId);
    final workerSnapshot = await workerRef.get();

    if (workerSnapshot.exists) {
      // Fetch existing worker details
      final workerData = workerSnapshot.data();
      if (workerData != null) {
        selectedMessBlock = workerData['messBlock'];
        selectedGender = workerData['gender'];
        nameController.text = workerData['name']; // Auto-fill the name
      }
    } else {
      // Save new worker details
      await workerRef.set({
        'name': nameController.text,
        'employeeId': empId,
        'gender': selectedGender,
        'messBlock': selectedMessBlock,
      });
    }

    // Navigate to dashboard
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessWorkerDashboard(
            messInChargeName: nameController.text,
            employeeId: empId,
            genderSide: selectedGender ?? '',
            messBlock: selectedMessBlock ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Worker Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: employeeIdController,
                decoration: const InputDecoration(labelText: 'Employee ID'),
                validator: (value) => value!.isEmpty ? 'Enter employee ID' : null,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Select Gender'),
                value: selectedGender,
                items: genderSides.map((side) => DropdownMenuItem(value: side, child: Text(side))).toList(),
                onChanged: (value) => setState(() => selectedGender = value as String?),
                validator: (value) => value == null ? 'Select gender' : null,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Select Mess Block'),
                value: selectedMessBlock,
                items: messBlocks.map((block) => DropdownMenuItem(value: block, child: Text(block))).toList(),
                onChanged: (value) => setState(() => selectedMessBlock = value as String?),
                validator: (value) => value == null ? 'Select mess block' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    saveWorkerData();
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
