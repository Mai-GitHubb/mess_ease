import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, Map<String, bool>> selectedItems;
  final int totalCost;
  final int creditsUsedToday;
  final int dailyCredit;
  final String userId;
  final bool useCredits; // Add useCredits flag

  const CheckoutPage({
    super.key,
    required this.selectedItems,
    required this.totalCost,
    required this.creditsUsedToday,
    required this.dailyCredit,
    required this.userId,
    required this.useCredits,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // ... (rest of the CheckoutPage code)
            Text(
              'Total Cost: ₹$totalCost',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Credits Used Today: $creditsUsedToday'),
            Text('Daily Credit Remaining: ${dailyCredit - creditsUsedToday}'),
            ElevatedButton(
              onPressed: () {
                _confirmPayment(context);
              },
              child: const Text("Confirm Payment"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context) async {
    try {
      if (useCredits) {
        // Deduct from user credits
        DocumentReference userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userRef);
          if (snapshot.exists) {
            int currentCredits =
                (snapshot.data() as Map<String, dynamic>)['credits'] ?? 0;
            transaction.update(userRef, {
              'credits': currentCredits - totalCost,
            });
          }
        });
      }
      Navigator.pop(context); // Go back to the menu page
    } catch (e) {
      print('Error confirming payment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment Failed')));
    }
  }

  Future<int> _getItemPrice(String meal, String itemName) async {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final collectionPath = 'mess_menus/K-block/$formattedDate/$meal/items';

    final itemSnapshot =
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .where('name', isEqualTo: itemName)
            .get();

    if (itemSnapshot.docs.isNotEmpty) {
      return (itemSnapshot.docs.first.data() as Map<String, dynamic>)['price']
          as int;
    } else {
      return 0; // Or throw an exception if price is crucial
    }
  }
}
