import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SniperDashboardScreen(),
    );
  }
}

//////////////////////////////////////////////////////////////
// 🏠 ADD SNIPE SCREEN & SNIPER DASHBOARD COMBINED
//////////////////////////////////////////////////////////////

class SniperDashboardScreen extends StatefulWidget {
  const SniperDashboardScreen({super.key});

  @override
  State<SniperDashboardScreen> createState() => _SniperDashboardScreenState();
}

class _SniperDashboardScreenState extends State<SniperDashboardScreen> {
  // Variables for the form (Add Snipe)
  final TextEditingController urlController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isLoading = false;

  // Variables for the Snipes List (Dashboard)
  List<dynamic> snipes = [];
  Timer? _timer;

  final String apiUrl = "http://192.168.68.105:8000/get_snipes";
  final String addApi = "http://192.168.68.105:8000/add_snipe";

  // Add new Snipe to the Backend
  Future<void> addSnipe() async {
    if (urlController.text.isEmpty || priceController.text.isEmpty) return;

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse(addApi),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "url": urlController.text,
        "target_price": double.parse(priceController.text)
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      fetchSnipes(); // Fetch the updated snipes list
      urlController.clear(); // Clear input fields
      priceController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add snipe")),
      );
    }
  }

  // Fetch snipes from backend
  Future<void> fetchSnipes() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        snipes = data["snipes"];
      });
    }
  }

  // Auto fetch snipes every 5 seconds
  @override
  void initState() {
    super.initState();
    fetchSnipes();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchSnipes());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sniper Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Activate New Sniper",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: "Product URL",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Target Price",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : addSnipe,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              "Activate Sniper",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
      body: snipes.isEmpty
          ? const Center(child: Text("No snipes yet"))
          : ListView.builder(
        itemCount: snipes.length,
        itemBuilder: (context, index) {
          final snipe = snipes[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text("Target: ${snipe['target_price']}"),
              subtitle: Text("Current: ${snipe['current_price']}"),
              trailing: Text(
                snipe['status'],
                style: TextStyle(
                  color: snipe['status'] == "Target Hit"
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}