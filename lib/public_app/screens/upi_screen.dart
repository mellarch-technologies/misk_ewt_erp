// lib/public_app/screens/upi_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/public_donation_service.dart';
import '../services/public_settings_service.dart';

class UpiScreen extends StatefulWidget {
  const UpiScreen({super.key});

  @override
  State<UpiScreen> createState() => _UpiScreenState();
}

class _UpiScreenState extends State<UpiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _utr = TextEditingController();

  bool _submitting = false;

  // Live settings
  Map<String, dynamic>? _payments;
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final svc = PublicSettingsService();
    final p = await svc.getPayments();
    if (mounted) setState(() { _payments = p; _loadingSettings = false; });
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _utr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amt = num.tryParse(_amount.text.trim()) ?? 0;
    setState(() => _submitting = true);
    try {
      await PublicDonationService().submitPendingDonation({
        'method': 'upi',
        'amount': amt,
        'donorName': _name.text.trim(),
        'donorEmail': _email.text.trim(),
        'donorPhone': _phone.text.trim(),
        'utr': _utr.text.trim().isEmpty ? null : _utr.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted. We will verify and confirm soon.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _upiPanel() {
    if (_loadingSettings) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text('Loading UPI details...'),
      );
    }
    final vpa = (_payments?['upiVpa'] as String?) ?? 'VPA not set';
    final feeNote = (_payments?['recommend']?['upiFixedFeeNote'] as String?) ?? 'Your bank may charge a fee.';
    final qrUrl = (_payments?['upiQrcodeUrl'] as String?);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Text('VPA: $vpa\n$feeNote'),
        ),
        if (qrUrl != null && qrUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(qrUrl, height: 180, fit: BoxFit.cover),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay via your UPI app to:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _upiPanel(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (INR)'),
                validator: (v) {
                  final n = num.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Your Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _utr,
                decoration: const InputDecoration(labelText: 'UPI Ref/UTR (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting...' : 'Submit UPI details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
