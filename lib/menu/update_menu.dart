import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UpdateMenuPage extends StatefulWidget {
  final String empId; // Employee ID of logged-in worker

  const UpdateMenuPage({super.key, required this.empId});

  @override
  State<UpdateMenuPage> createState() => _UpdateMenuPageState();
}

class _UpdateMenuPageState extends State<UpdateMenuPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? messBlock;
  String? selectedMeal;
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  final Map<String, Map<String, int>> predefinedItems = {
    'Breakfast': {
      'Masala Omelette': 35,
      'Idli Sambar': 30,
      'Poha': 25,
      'Upma': 30,
      'Fruit Salad': 40,
      'Sprouts Salad': 35,
      'Banana Smoothie': 45,
    },
    'Lunch': {
      'Veg Biryani': 70,
      'Chicken Curry with Rice': 90,
      'Rajma Chawal': 65,
      'Palak Paneer with Roti': 80,
      'Fish Fry with Rice': 100,
      'Mixed Dal with Jeera Rice': 75,
      'Lemon Rice': 60,
    },
    'Snacks': {
      'Samosa': 20,
      'Veg Puff': 25,
      'Aloo Bonda': 20,
      'Fruit Chat': 35,
      'Tea/Coffee': 15,
      'Popcorn': 30,
      'Sandwich': 40,
    },
    'Dinner': {
      'Chicken Noodles': 85,
      'Veg Fried Rice': 70,
      'Mushroom Curry with Roti': 80,
      'Egg Bhurji with Paratha': 75,
      'Paneer Tikka Masala': 95,
      'Dal Tadka with Rice': 65,
      'Soup': 45,
    },
  };

  final Map<String, bool> selectedItems = {}; // Tracks selected checkboxes
  final TextEditingController specialItemController = TextEditingController();
  final TextEditingController specialPriceController = TextEditingController();
  final TextEditingController juiceNameController = TextEditingController();
  final TextEditingController juicePriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWorkerDetails();
  }

  Future<void> fetchWorkerDetails() async {
    final workerSnapshot =
        await firestore.collection('mess_workers').doc(widget.empId).get();
    if (workerSnapshot.exists) {
      setState(() {
        messBlock = workerSnapshot.data()?['messBlock'];
      });
    }
  }

  void updateMenu() async {
    if (messBlock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading mess details...')));
      return;
    }
    if (selectedMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Meal Type!')));
      return;
    }

    final String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String menuCollectionPath =
        'mess_menus/$messBlock/$todayDate/$selectedMeal/items'; // Corrected Path

    try {
      final selectedMenuItems = selectedItems.entries
          .where((entry) => entry.value)
          .map((entry) => {
                'name': entry.key,
                'price': predefinedItems[selectedMeal]![entry.key]
              })
          .toList();

      if (specialItemController.text.isNotEmpty &&
          specialPriceController.text.isNotEmpty) {
        selectedMenuItems.add({
          'name': specialItemController.text,
          'price': int.tryParse(specialPriceController.text) ?? 0
        });
      }
      if (juiceNameController.text.isNotEmpty &&
          juicePriceController.text.isNotEmpty) {
        selectedMenuItems.add({
          'name': juiceNameController.text,
          'price': int.tryParse(juicePriceController.text) ?? 0
        });
      }

      // Delete existing documents in the subcollection
      final existingDocs = await firestore.collection(menuCollectionPath).get();
      for (var doc in existingDocs.docs) {
        await firestore.collection(menuCollectionPath).doc(doc.id).delete();
      }

      // Add new documents
      for (var item in selectedMenuItems) {
        await firestore.collection(menuCollectionPath).add(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Updated Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Menu')),
      body: messBlock == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField(
                    decoration:
                        const InputDecoration(labelText: 'Select Meal Type'),
                    value: selectedMeal,
                    items: mealTypes
                        .map((meal) =>
                            DropdownMenuItem(value: meal, child: Text(meal)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMeal = value as String?;
                        selectedItems.clear(); // Reset checkboxes when meal type changes
                        for (var item in predefinedItems[selectedMeal ?? 'Breakfast']!.keys) {
                          selectedItems[item] = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedMeal != null) ...[
                    const Text('Select Items:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView(
                        children: predefinedItems[selectedMeal]?.keys.map((item) {
                          return CheckboxListTile(
                            title: Text(
                                '$item - ₹${predefinedItems[selectedMeal]?[item]}'),
                            value: selectedItems[item] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedItems[item] = value!;
                              });
                            },
                          );
                        }).toList() ?? [], // Null check added here, providing empty list as default
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Add Special Items:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: specialItemController,
                      decoration:
                          const InputDecoration(labelText: 'Special Item Name'),
                    ),
                    TextField(
                      controller: specialPriceController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Special Item Price'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Add Juice:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: juiceNameController,
                      decoration: const InputDecoration(labelText: 'Juice Name'),
                    ),
                    TextField(
                      controller: juicePriceController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Juice Price'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: updateMenu, child: const Text('Update Menu')),
                  ],
                ],
              ),
            ),
    );
  }
}