// lib/screens/settings/global_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../roles/roles_list_screen.dart';
import '../security/app_lock_settings_screen.dart';
import '../../theme/app_theme.dart';
import 'payment_settings_screen.dart';
import '../../services/rollup_service.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/back_or_home_button.dart';
import 'package:http/http.dart' as http;
import '../../services/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/search_input.dart';

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  final _search = TextEditingController();
  bool _busyRollups = false;
  String? _errorMsg;
  Timestamp? _lastRunAt;
  int? _lastRunMs;
  String? _lastRunBy;

  @override
  void initState() {
    super.initState();
    _loadRollupMetrics();
  }

  Future<void> _loadRollupMetrics() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admin').doc('rollups').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _lastRunAt = data['lastRunAt'] as Timestamp?;
          _lastRunMs = (data['lastRunDurationMs'] is int) ? data['lastRunDurationMs'] as int : (data['lastRunDurationMs'] as num?)?.toInt();
          _lastRunBy = data['lastRunBy'] as String?;
        });
      }
    } catch (_) {}
  }

  // Simple reachability ping for the configured uploads endpoint
  Future<void> _pingUploads(BuildContext context) async {
    final cfg = AppConfig.photoStorage;
    if (cfg.backend == PhotoBackend.none) {
      SnackbarHelper.showInfo(context, 'Uploads backend: none (disabled)');
      return;
    }
    final url = cfg.endpointUrl;
    if (url == null || url.isEmpty) {
      SnackbarHelper.showError(context, 'Uploads endpoint URL not set');
      return;
    }
    try {
      final uri = Uri.parse(url);
      final sw = Stopwatch()..start();
      // Use GET to test reachability; many endpoints will 405 on GET but that still proves reachability.
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      sw.stop();
      final ok = resp.statusCode < 500; // treat 2xx/3xx/4xx as reachable
      if (ok) {
        SnackbarHelper.showSuccess(context, 'Uploads reachable (${resp.statusCode}) in ${sw.elapsedMilliseconds} ms');
      } else {
        SnackbarHelper.showError(context, 'Uploads unreachable (${resp.statusCode})');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Ping failed: $e');
    }
  }

  Future<void> _runRollups() async {
    setState(() {
      _busyRollups = true;
      _errorMsg = null;
    });
    final sw = Stopwatch()..start();
    try {
      final snap = await FirebaseFirestore.instance.collection('initiatives').get();
      final svc = RollupService();
      for (final doc in snap.docs) {
        await svc.recomputeInitiativeFinancial(doc.reference);
      }
      sw.stop();
      // Write metrics
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('admin').doc('rollups').set({
        'lastRunAt': FieldValue.serverTimestamp(),
        'lastRunDurationMs': sw.elapsedMilliseconds,
        'lastRunBy': user?.email ?? user?.uid ?? 'unknown',
      }, SetOptions(merge: true));
      await _loadRollupMetrics();
      if (mounted) SnackbarHelper.showSuccess(context, 'Roll-ups complete for ${snap.docs.length} initiatives');
    } catch (e) {
      sw.stop();
      setState(() => _errorMsg = 'Failed to run roll-ups: $e');
    } finally {
      if (mounted) setState(() => _busyRollups = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: MiskTheme.miskGold),
        title: const Text('Roles & Permissions'),
        subtitle: const Text('Manage roles and permissions for all users'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesListScreen())),
      ),
      ListTile(
        leading: const Icon(Icons.security, color: MiskTheme.miskGold),
        title: const Text('Security & App Lock'),
        subtitle: const Text('Enable app lock, set PIN/biometrics, idle timeout'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLockSettingsScreen())),
      ),
      ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: MiskTheme.miskGold),
        title: const Text('Payments'),
        subtitle: const Text('Razorpay, UPI and Bank details for Public App'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
      ),
      // Uploads backend status and ping
      Builder(
        builder: (ctx) {
          final cfg = AppConfig.photoStorage;
          final backendLabel = () {
            switch (cfg.backend) {
              case PhotoBackend.none:
                return 'none (disabled)';
              case PhotoBackend.sharedHosting:
                return 'sharedHosting';
              case PhotoBackend.googleDrive:
                return 'googleDrive';
            }
          }();
          final endpoint = cfg.endpointUrl ?? 'Not set';
          return ListTile(
            leading: const Icon(Icons.cloud_upload, color: MiskTheme.miskGold),
            title: const Text('Uploads backend'),
            subtitle: Text('Backend: $backendLabel\nEndpoint: $endpoint'),
            isThreeLine: true,
            trailing: TextButton.icon(
              onPressed: () => _pingUploads(ctx),
              icon: const Icon(Icons.network_check),
              label: const Text('Test'),
            ),
          );
        },
      ),
      // Recompute roll-ups panel
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: MiskTheme.spacingSmall),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recompute roll-ups', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _lastRunAt != null
                      ? 'Last run: ${_lastRunAt!.toDate().toLocal()} • Duration: ${_lastRunMs ?? '-'} ms • By: ${_lastRunBy ?? '-'}'
                      : 'No previous run info',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _busyRollups
                        ? null
                        : () async {
                            // confirm
                            final initCount = (await FirebaseFirestore.instance.collection('initiatives').count().get()).count ?? 0;
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Run roll-ups?'),
                                content: Text('This will recompute financial totals for $initCount initiative(s). Proceed?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Run')),
                                ],
                              ),
                            );
                            if (ok == true) await _runRollups();
                          },
                    icon: _busyRollups
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: Text(_busyRollups ? 'Running…' : 'Run roll-ups'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? tiles
        : tiles.where((w) {
            if (w is ListTile) {
              final t = (w.title is Text) ? ((w.title as Text).data ?? '') : '';
              final s = (w.subtitle is Text) ? ((w.subtitle as Text).data ?? '') : '';
              return t.toLowerCase().contains(q) || s.toLowerCase().contains(q);
            }
            if (w is Padding) return true; // keep roll-ups panel always visible
            return false;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Settings'),
        leading: const BackOrHomeButton(),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(MiskTheme.spacingMedium),
            child: SearchInput(controller: _search, hintText: 'Search settings...', onChanged: (_) => setState(() {})),
          ),
          ...filtered,
          const SizedBox(height: MiskTheme.spacingMedium),
        ],
      ),
    );
  }
}
