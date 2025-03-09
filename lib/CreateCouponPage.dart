import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class CreateCouponPage extends StatefulWidget {
  @override
  _CreateCouponPageState createState() => _CreateCouponPageState();
}

class _CreateCouponPageState extends State<CreateCouponPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child("coupons");

  void _saveCoupon() {
    String name = _nameController.text.trim();
    String discountText = _discountController.text.trim();

    if (name.isEmpty || discountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter all fields")),
      );
      return;
    }

    int discount = int.tryParse(discountText) ?? 0;
    if (discount <= 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Discount must be between 1 and 100")),
      );
      return;
    }

    String couponId = Uuid().v4(); // Generate unique ID
    Coupon coupon = Coupon(id: couponId, name: name, discount: discount);

    _database.child(couponId).set(coupon.toJson()).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Coupon Added Successfully")),
      );
      _nameController.clear();
      _discountController.clear();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add coupon: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Coupon")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Coupon Name"),
            ),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Discount (%)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCoupon,
              child: Text("Create Coupon"),
            ),
          ],
        ),
      ),
    );
  }
}

class Coupon {
  String id;
  String name;
  int discount;

  Coupon({required this.id, required this.name, required this.discount});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'discount': discount,
    };
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      name: json['name'],
      discount: json['discount'],
    );
  }
}
