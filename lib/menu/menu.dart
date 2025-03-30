import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'checkout_page.dart';

class MenuPage extends StatefulWidget {
  final bool isSubscribed;
  final String userId;

  const MenuPage({super.key, required this.isSubscribed, required this.userId});

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, Map<String, bool>> selectedItems = {};
  String messBlock = 'K-block';
  int dailyCredit = 400;
  int creditsUsedToday = 0;
  int userCredit = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserCredit();
  }

  Future<void> _fetchUserCredit() async {
    if (widget.isSubscribed) {
      try {
        DocumentSnapshot userSnapshot =
            await firestore.collection('users').doc(widget.userId).get();
        if (userSnapshot.exists) {
          setState(() {
            userCredit =
                (userSnapshot.data() as Map<String, dynamic>)['credits'] ?? 0;
          });
        }
      } catch (e) {
        // Replace print with logging framework if needed
        print('Error fetching user credits: $e');
      }
    }
  }

  Stream<QuerySnapshot> getMenuItemsStream(String meal) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final collectionPath = 'mess_menus/K-block/$formattedDate/$meal/items';

    // Replace print with logging framework if needed
    print("DEBUG: Fetching from PATH: $collectionPath");
    return firestore.collection(collectionPath).snapshots().map((snapshot) {
      // Replace print with logging framework if needed
      print("DEBUG: Snapshot docs length: ${snapshot.docs.length}");
      for (var doc in snapshot.docs) {
        // Replace print with logging framework if needed
        print("DEBUG: Document data: ${doc.data()}");
      }
      return snapshot;
    });
  }

  bool isPurchaseAvailable() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    if (hour == 6 && minute >= 40 ||
        hour == 7 ||
        hour == 8 ||
        (hour == 9 && minute == 0)) {
      return true;
    }
    if (hour == 12 && minute >= 10 ||
        hour == 13 ||
        (hour == 14 && minute <= 30)) {
      return true;
    }
    if (hour == 16 && minute >= 10 ||
        hour == 17 ||
        (hour == 18 && minute == 0)) {
      return true;
    }
    if (hour == 18 && minute >= 40 ||
        hour == 19 ||
        hour == 20 ||
        (hour == 21 && minute == 0)) {
      return true;
    }

    return false;
  }

  int calculateTotalCost(Map<String, Map<String, bool>> selected) {
    int totalCost = 0;
    selected.forEach((meal, items) {
      if (items != null) {
        items.forEach((item, isSelected) async {
          if (isSelected) {
            final now = DateTime.now();
            final formattedDate = DateFormat('dd-MM-yyyy').format(now);
            final collectionPath =
                'mess_menus/K-block/$formattedDate/$meal/items';

            final itemSnapshot =
                await firestore
                    .collection(collectionPath)
                    .where('name', isEqualTo: item)
                    .get();

            if (itemSnapshot.docs.isNotEmpty) {
              totalCost +=
                  ((itemSnapshot.docs.first.data())['price'] as num?)
                      ?.toInt() ??
                  0;
            }
          }
        });
      }
    });
    return totalCost;
  }

  bool isWithinMealTime(String meal) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    switch (meal) {
      case 'Breakfast':
        return (hour == 6 && minute >= 20) ||
            hour == 7 ||
            hour == 8 ||
            (hour == 9 && minute <= 0);
      case 'Lunch':
        return (hour == 11 && minute >= 50) ||
            hour == 12 ||
            hour == 13 ||
            (hour == 14 && minute <= 30);
      case 'Snacks':
        return (hour == 15 && minute >= 50) ||
            hour == 16 ||
            hour == 17 ||
            (hour == 18 && minute <= 0);
      case 'Dinner':
        return (hour == 18 && minute >= 20) ||
            hour == 19 ||
            hour == 20 ||
            (hour == 21 && minute <= 0);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Page')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSubscribed)
              Text(
                'Credits Remaining: $userCredit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ...['Breakfast', 'Lunch', 'Snacks', 'Dinner'].map((meal) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: getMenuItemsStream(meal),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No $meal items available.');
                      }

                      List<Map<String, dynamic>> items =
                          snapshot.data!.docs
                              .map((doc) => doc.data() as Map<String, dynamic>)
                              .toList();

                      if (selectedItems[meal] == null) {
                        selectedItems[meal] = {};
                      }

                      return Column(
                        children:
                            items.map((item) {
                              return isWithinMealTime(meal)
                                  ? CheckboxListTile(
                                    title: Text(
                                      '${item['name']} - ₹${item['price']}',
                                    ),
                                    value:
                                        selectedItems[meal]![item['name']] ??
                                        false,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (selectedItems[meal] == null) {
                                          selectedItems[meal] = {};
                                        }
                                        selectedItems[meal]![item['name']] =
                                            value ?? false;
                                      });
                                    },
                                  )
                                  : ListTile(
                                    title: Text(
                                      '${item['name']} - ₹${item['price']}',
                                    ),
                                  );
                            }).toList(), // Corrected line
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
            if (isPurchaseAvailable())
              ElevatedButton(
                onPressed: () {
                  int totalCost = calculateTotalCost(selectedItems);
                  if (widget.isSubscribed && userCredit >= totalCost) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutPage(
                              selectedItems: selectedItems,
                              totalCost: totalCost,
                              creditsUsedToday: creditsUsedToday,
                              dailyCredit: dailyCredit,
                              userId: widget.userId,
                              useCredits: true,
                            ),
                      ),
                    );
                  } else if (dailyCredit - creditsUsedToday >= totalCost) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutPage(
                              selectedItems: selectedItems,
                              totalCost: totalCost,
                              creditsUsedToday: creditsUsedToday,
                              dailyCredit: dailyCredit,
                              userId: widget.userId,
                              useCredits: false,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Insufficient Credits")),
                    );
                  }
                },
                child: const Text("Proceed to Checkout"),
              ),
          ],
        ),
      ),
    );
  }
}
