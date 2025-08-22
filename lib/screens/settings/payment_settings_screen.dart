import 'package:flutter/material.dart';
import '../../widgets/snackbar_helper.dart';
import '../../services/payment_settings_service.dart';
import '../../theme/app_theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = PaymentSettingsService();
  bool _busy = true;

  // Controllers
  final _razorpayKeyId = TextEditingController();
  final _razorpayNotes = TextEditingController();
  bool _enableRazorpay = false;

  final _upiVpa = TextEditingController();
  final _upiQrUrl = TextEditingController();

  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankBranch = TextEditingController();

  final _minBankPreferred = TextEditingController();
  final _upiFeeNote = TextEditingController();
  bool _showCoverFeesToggle = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _svc.load();
      setState(() {
        _enableRazorpay = (data['enableRazorpay'] as bool?) ?? false;
        _razorpayKeyId.text = (data['razorpayKeyId'] ?? '').toString();
        _razorpayNotes.text = (data['razorpayNotes'] ?? '').toString();
        _upiVpa.text = (data['upiVpa'] ?? '').toString();
        _upiQrUrl.text = (data['upiQrcodeUrl'] ?? '').toString();
        final bank = (data['bank'] as Map<String, dynamic>?) ?? {};
        _bankName.text = (bank['name'] ?? '').toString();
        _bankAccount.text = (bank['accountNumber'] ?? '').toString();
        _bankIfsc.text = (bank['ifsc'] ?? '').toString();
        _bankBranch.text = (bank['branch'] ?? '').toString();
        final rec = (data['recommend'] as Map<String, dynamic>?) ?? {};
        _minBankPreferred.text = (rec['minAmountBankPreferred']?.toString() ?? '2000');
        _upiFeeNote.text = (rec['upiFixedFeeNote'] ?? '₹6 may apply (ICICI)').toString();
        _showCoverFeesToggle = (rec['showCoverFeesToggle'] as bool?) ?? true;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) SnackbarHelper.showError(context, 'Failed to load settings: $e');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final minAmt = num.tryParse(_minBankPreferred.text.trim());
    final payload = <String, dynamic>{
      'enableRazorpay': _enableRazorpay,
      'razorpayKeyId': _razorpayKeyId.text.trim(),
      'razorpayNotes': _razorpayNotes.text.trim(),
      'upiVpa': _upiVpa.text.trim(),
      'upiQrcodeUrl': _upiQrUrl.text.trim(),
      'bank': {
        'name': _bankName.text.trim(),
        'accountNumber': _bankAccount.text.trim(),
        'ifsc': _bankIfsc.text.trim(),
        'branch': _bankBranch.text.trim(),
      },
      'recommend': {
        'minAmountBankPreferred': minAmt ?? 2000,
        'upiFixedFeeNote': _upiFeeNote.text.trim(),
        'showCoverFeesToggle': _showCoverFeesToggle,
      },
    };
    try {
      setState(() => _busy = true);
      await _svc.save(payload);
      if (mounted) SnackbarHelper.showSuccess(context, 'Payment settings saved');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testConfig() async {
    final vpa = _upiVpa.text.trim();
    final ifsc = _bankIfsc.text.trim();
    final account = _bankAccount.text.trim();
    final keyId = _razorpayKeyId.text.trim();

    final vpaOk = vpa.contains('@') && vpa.indexOf('@') > 0;
    final ifscOk = RegExp(r'^[A-Z]{4}0[0-9A-Z]{6}?$').hasMatch(ifsc.toUpperCase());
    final acctOk = account.length >= 6;
    final rzOk = !_enableRazorpay || keyId.isNotEmpty;

    if (vpaOk && ifscOk && acctOk && rzOk) {
      SnackbarHelper.showSuccess(context, 'Config looks valid');
    } else {
      final problems = <String>[];
      if (!vpaOk) problems.add('UPI VPA');
      if (!ifscOk) problems.add('IFSC');
      if (!acctOk) problems.add('Account');
      if (!rzOk) problems.add('Razorpay Key ID');
      SnackbarHelper.showError(context, 'Check: ${problems.join(', ')}');
    }
  }

  @override
  void dispose() {
    _razorpayKeyId.dispose();
    _razorpayNotes.dispose();
    _upiVpa.dispose();
    _upiQrUrl.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _bankIfsc.dispose();
    _bankBranch.dispose();
    _minBankPreferred.dispose();
    _upiFeeNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        actions: [
          IconButton(
            tooltip: 'Test Config',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _busy ? null : _testConfig,
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(MiskTheme.spacingMedium),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text('Razorpay', style: TextStyle(fontWeight: FontWeight.w700)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Razorpay'),
                      value: _enableRazorpay,
                      onChanged: (v) => setState(() => _enableRazorpay = v),
                    ),
                    TextFormField(
                      controller: _razorpayKeyId,
                      decoration: const InputDecoration(labelText: 'Razorpay Key ID'),
                    ),
                    TextFormField(
                      controller: _razorpayNotes,
                      decoration: const InputDecoration(labelText: 'Razorpay Notes (optional)'),
                    ),
                    const Divider(height: 32),
                    const Text('UPI', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextFormField(
                      controller: _upiVpa,
                      decoration: const InputDecoration(labelText: 'UPI VPA (e.g., trust@icici)'),
                      validator: (v) => (v != null && v.contains('@')) ? null : 'Enter a valid VPA',
                    ),
                    TextFormField(
                      controller: _upiQrUrl,
                      decoration: const InputDecoration(labelText: 'UPI QR Code URL (optional)'),
                    ),
                    const Divider(height: 32),
                    const Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextFormField(
                      controller: _bankName,
                      decoration: const InputDecoration(labelText: 'Bank Name'),
                    ),
                    TextFormField(
                      controller: _bankAccount,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                    TextFormField(
                      controller: _bankIfsc,
                      decoration: const InputDecoration(labelText: 'IFSC'),
                    ),
                    TextFormField(
                      controller: _bankBranch,
                      decoration: const InputDecoration(labelText: 'Branch'),
                    ),
                    const Divider(height: 32),
                    const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextFormField(
                      controller: _minBankPreferred,
                      decoration: const InputDecoration(labelText: 'Min Amount for Bank Preferred (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _upiFeeNote,
                      decoration: const InputDecoration(labelText: 'UPI Fee Note (display to donors)'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show "Cover fees" toggle on Razorpay'),
                      value: _showCoverFeesToggle,
                      onChanged: (v) => setState(() => _showCoverFeesToggle = v),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _testConfig,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Test Config'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
