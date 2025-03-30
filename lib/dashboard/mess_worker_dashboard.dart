import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mess_ease/menu/update_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';


class MessWorkerDashboard extends StatefulWidget {
  final String messInChargeName;
  final String employeeId;
  final String genderSide;
  final String messBlock;

  const MessWorkerDashboard({
    super.key,
    required this.messInChargeName,
    required this.employeeId,
    required this.genderSide,
    required this.messBlock,
  });

  @override
  State<MessWorkerDashboard> createState() => _MessWorkerDashboardState();
}

class _MessWorkerDashboardState extends State<MessWorkerDashboard> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedMeal;
  List<Map<String, dynamic>> menuItems = [];
  bool isLoading = false;
  bool _excelLoading = false;

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchMenu() async {
    if (selectedMeal == null) {
      return;
    }

    setState(() => isLoading = true);

    final String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String menuCollectionPath =
        'mess_menus/${widget.messBlock}/$todayDate/${selectedMeal!}/items';

    try {
      final menuSnapshot = await firestore.collection(menuCollectionPath).get();

      if (menuSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedItems = [];
        for (var doc in menuSnapshot.docs) {
          fetchedItems.add(doc.data());
        }
        setState(() {
          menuItems = fetchedItems;
        });
      } else {
        setState(() {
          menuItems = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUsersFromExcel(BuildContext context) async {
    setState(() {
      _excelLoading = true;
    });
    try {
      var status = await Permission.storage.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied.')));
        }
        setState(() {
          _excelLoading = false;
        });
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        var fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          print('fileBytes: $fileBytes');
          print('fileBytes length: ${fileBytes.length}');

          try {
            var excel = Excel.decodeBytes(fileBytes);
            var table = excel.tables.keys.first;

            QuerySnapshot querySnapshot =
                await FirebaseFirestore.instance.collection('users').get();
            Map<String, DocumentSnapshot> existingUsers = {
              for (var doc in querySnapshot.docs) doc.id: doc
            };

            for (var row in excel.tables[table]!.rows.skip(1)) {
              if (row != null && row.isNotEmpty) {
                String regNo = row[0]?.value?.toString() ?? '';
                if (regNo.isEmpty) continue;
                Map<String, dynamic> userData = {};

                for (int i = 1; i < row.length; i++) {
                  String? header =
                      excel.tables[table]!.rows.first[i]?.value?.toString();
                  if (header != null && row[i]?.value != null) {
                    userData[header] = row[i]?.value;
                  }
                }

                QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('regNo', isEqualTo: regNo)
                    .get();

                if (userSnapshot.docs.isNotEmpty) {
                  String userId = userSnapshot.docs.first.id;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update(userData);
                  existingUsers.remove(userId);
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .add(userData);
                }
              }
            }

            for (var userId in existingUsers.keys) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Users updated from Excel.')));
            }
          } on ExcelException catch (e) {
            print('ExcelException: $e');
            print('Stack trace: ${e.stackTrace}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ExcelException: $e')));
            }
          } catch (e) {
            print('Error decoding Excel: $e');
            print('Stack trace: ${StackTrace.current}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error decoding Excel: $e')));
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error reading file bytes.')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No file selected.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      setState(() {
        _excelLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Worker Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${widget.messInChargeName}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Employee ID: ${widget.employeeId}',
                style: const TextStyle(fontSize: 16)),
            Text('Mess: ${widget.genderSide} - ${widget.messBlock}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UpdateMenuPage(empId: widget.employeeId)),
                );
              },
              child: const Text('Update Menu'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _excelLoading ? null : () => _updateUsersFromExcel(context),
              child: _excelLoading ? const CircularProgressIndicator() : const Text('Update Users from Excel'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Select Meal Type'),
              value: selectedMeal,
              items: mealTypes
                  .map((meal) =>
                      DropdownMenuItem(value: meal, child: Text(meal)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMeal = value as String?;
                  fetchMenu();
                });
              },
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuItems.isEmpty
                    ? const Center(
                        child:
                            Text('No menu available for the selected meal.'))
                    : Column(
                        key: ValueKey(menuItems.length),
                        children: menuItems.map((item) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(item['name'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text('Price: ₹${item['price']}'),
                              ),
                              const Divider(),
                            ],
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}