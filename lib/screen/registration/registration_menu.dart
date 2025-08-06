import 'package:flutter/material.dart';
import 'manual_form.dart';
import 'capture_form.dart';

class RegistrationMenu extends StatelessWidget {
  const RegistrationMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เมนูลงทะเบียน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Option(
              icon: Icons.edit_note,
              title: 'กรอกเอง',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualForm()),
              ),
            ),
            const SizedBox(height: 24),
            _Option(
              icon: Icons.camera_alt,
              title: 'ลงทะเบียนด้วยบัตรประชาชน',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaptureForm()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _Option({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 40),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
