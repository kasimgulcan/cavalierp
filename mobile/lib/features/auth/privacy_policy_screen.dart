import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'CavaliERP mobil uygulaması sipariş talebi ve hesap yönetimi amacıyla '
            'hesap bilgilerinizi ve işlem verilerinizi işler. Verileriniz üçüncü '
            'taraflarla paylaşılmaz. Hesabınızı uygulama içinden silebilirsiniz.\n\n'
            'TODO: Resmi gizlilik politikası metni buraya eklenecek.',
          ),
        ),
      ),
    );
  }
}
