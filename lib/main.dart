import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // already generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore List',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2962FF)),
      home: const ItemListApp(),
    );
  }
}

class ItemListApp extends StatefulWidget {
  const ItemListApp({super.key});

  @override
  State<ItemListApp> createState() => _ItemListAppState();
}

class _ItemListAppState extends State<ItemListApp> {
  final TextEditingController _newItemTextField = TextEditingController();

  late final CollectionReference<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = FirebaseFirestore.instance.collection('ITEMS');
  }

  // Add a new item to Firestore
  Future<void> _addItem() async {
    final newItem = _newItemTextField.text.trim();
    if (newItem.isEmpty) return;

    await items.add({
      'item_name': newItem,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _newItemTextField.clear();
  }

  // Remove an item from Firestore by document ID
  Future<void> _removeItemAt(String id) async {
    await items.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore List Demo')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // ====== Item Input  ======
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemTextField,
                    onSubmitted: (_) => _addItem(),
                    decoration: const InputDecoration(
                      labelText: 'New Item Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _addItem, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 24),
            // ====== Firestore Item List ======
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: items.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading items'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No items yet. Tap + to add.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final name = doc.data()['item_name'] ?? 'Unnamed';

                      return Dismissible(
                        key: ValueKey(doc.id),
                        background: Container(color: Colors.red),
                        onDismissed: (_) => _removeItemAt(doc.id),
                        child: ListTile(
                          leading: const Icon(Icons.check_box),
                          title: Text(name),
                          onTap: () => _removeItemAt(doc.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
