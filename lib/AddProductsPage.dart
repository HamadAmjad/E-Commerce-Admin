import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _imageControllers = [TextEditingController()]; // List for multiple images

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim());

      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid price')),
        );
        return;
      }

      // Collect all image URLs
      final List<String> imageUrls = _imageControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image URL')),
        );
        return;
      }

      try {
        final databaseRef = FirebaseDatabase.instance.ref('products');
        await databaseRef.push().set({
          'name': name,
          'price': price,
          'category': category,
          'description': description,
          'imageUrls': imageUrls, // Store images as a list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context); // Go back to the previous page
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $error')),
        );
      }
    }
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    setState(() {
      _imageControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.cyanAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter product name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Please enter product price' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Product Category'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter product category' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Product Description'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter product description' : null,
              ),

              const SizedBox(height: 10),
              const Text('Product Images:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              // Dynamically adding image fields
              for (int i = 0; i < _imageControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageControllers[i],
                          decoration: const InputDecoration(labelText: 'Image URL'),
                          validator: (value) =>
                          value!.isEmpty ? 'Enter image URL' : null,
                        ),
                      ),
                      if (_imageControllers.length > 1) // Show remove button if more than one field
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeImageField(i),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addImageField,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('+ Add Another Image', style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                child: const Text(
                  'Add Product',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
