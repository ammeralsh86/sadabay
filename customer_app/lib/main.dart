import 'package:flutter/material.dart';

void main() {
  runApp(const MadaPayCustomer());
}

class MadaPayCustomer extends StatelessWidget {
  const MadaPayCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mada Pay',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mada Pay'),
        ),
        body: const Center(
          child: Text(
            'تطبيق العميل',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
