// lib/public_app/screens/bank_transfer_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/public_donation_service.dart';
import '../services/public_settings_service.dart';

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pan = TextEditingController();
  final _address = TextEditingController();
  final _bankRef = TextEditingController();
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
    _pan.dispose();
    _address.dispose();
    _bankRef.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amt = num.tryParse(_amount.text.trim()) ?? 0;
    setState(() => _submitting = true);
    try {
      await PublicDonationService().submitPendingDonation({
        'method': 'bank',
        'amount': amt,
        'donorName': _name.text.trim(),
        'donorEmail': _email.text.trim(),
        'donorPhone': _phone.text.trim(),
        'pan': _pan.text.trim().isEmpty ? null : _pan.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'bankRef': _bankRef.text.trim().isEmpty ? null : _bankRef.text.trim(),
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

  Widget _bankPanel() {
    if (_loadingSettings) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text('Loading bank details...'),
      );
    }
    final bank = (_payments != null ? _payments!['bank'] as Map<String, dynamic>? : null) ?? {};
    final name = (bank['name'] as String?) ?? 'Bank name';
    final account = (bank['accountNumber'] as String?) ?? 'Account number';
    final ifsc = (bank['ifsc'] as String?) ?? 'IFSC';
    final branch = (bank['branch'] as String?) ?? 'Branch';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Text('MISK Educational & Welfare Trust\n$name\nA/C: $account\nIFSC: $ifsc\nBranch: $branch'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Transfer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiskTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transfer to:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _bankPanel(),
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
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankRef,
                decoration: const InputDecoration(labelText: 'Bank Ref / UTR (optional)'),
              ),
              const SizedBox(height: 8),
              // PAN & Address gate for >= 10000
              Builder(builder: (context) {
                final amt = num.tryParse(_amount.text.trim()) ?? 0;
                final needsPan = amt >= 10000;
                return Column(
                  children: [
                    TextFormField(
                      controller: _pan,
                      decoration: InputDecoration(labelText: 'PAN${needsPan ? ' (required ≥ ₹10,000)' : ' (optional)'}'),
                      validator: (_) {
                        if (needsPan && _pan.text.trim().isEmpty) return 'PAN is required for ₹10,000 and above';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address,
                      decoration: InputDecoration(labelText: 'Address${needsPan ? ' (required ≥ ₹10,000)' : ' (optional)'}'),
                      validator: (_) {
                        if (needsPan && _address.text.trim().isEmpty) return 'Address is required for ₹10,000 and above';
                        return null;
                      },
                      maxLines: 2,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting...' : 'Submit transfer details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
