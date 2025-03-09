import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('orders');
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    _ordersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
        event.snapshot.value as Map<dynamic, dynamic>;

        List<Map<String, dynamic>> allOrders = [];

        data.forEach((userId, orders) {
          if (orders is Map<dynamic, dynamic>) {
            orders.forEach((orderId, orderData) {
              allOrders.add({
                'orderId': orderId,
                'userId': userId,
                'name': orderData['name'],
                'phone': orderData['phone'],
                'email': orderData['email'],
                'address': orderData['address'],
                'items': orderData['items'],
                'orderDate': DateTime.parse(orderData['orderDate']),
              });
            });
          }
        });

        allOrders.sort((a, b) => b['orderDate'].compareTo(a['orderDate']));

        setState(() {
          _allOrders = allOrders;
          _filteredOrders = allOrders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allOrders = [];
          _filteredOrders = [];
          _isLoading = false;
        });
      }
    });
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        bool matchesSearch = order['orderId'].toLowerCase().contains(_searchQuery) ||
            order['name'].toLowerCase().contains(_searchQuery) ||
            order['phone'].toLowerCase().contains(_searchQuery) ||
            order['email'].toLowerCase().contains(_searchQuery);

        bool matchesDate = _selectedDate == null ||
            DateFormat('yyyy-MM-dd').format(order['orderDate']) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!);

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _filteredOrders = _allOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders (Seller)', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.cyanAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.black),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: _filterOrders,
              decoration: InputDecoration(
                labelText: 'Search by Order ID, Name, Phone, or Email',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? const Center(child: Text('No orders found!'))
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                final orderTime =
                DateFormat('yyyy-MM-dd HH:mm').format(order['orderDate']);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order['orderId']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Order Time: $orderTime',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                        const Divider(),
                        Text('Name: ${order['name']}'),
                        Text('Phone: ${order['phone']}'),
                        Text('Email: ${order['email']}'),
                        Text('Address: ${order['address']}'),
                        const SizedBox(height: 8),
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Column(
                          children: List.generate(
                            (order['items'] as List).length,
                                (i) => ListTile(
                              leading: (order['items'][i]['imageUrl'] ?? '').isNotEmpty
                                  ? Image.network(
                                order['items'][i]['imageUrl'],
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                              )
                                  : const Icon(Icons.broken_image),
                              title: Text(order['items'][i]['name'] ?? 'Unknown'),
                              subtitle: Text(
                                'Price: \$${order['items'][i]['price']} x ${order['items'][i]['quantity']}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
