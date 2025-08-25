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
import '../../widgets/content_header.dart';

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key, this.inShell = false});
  final bool inShell;

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
  String _uploadsConnectionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadRollupMetrics();
    _checkUploadsStatus();
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

  // Enhanced uploads status check
  Future<void> _checkUploadsStatus() async {
    final cfg = AppConfig.photoStorage;
    if (cfg.backend == PhotoBackend.none) {
      setState(() => _uploadsConnectionStatus = 'Disabled');
      return;
    }

    final url = cfg.endpointUrl;
    if (url == null || url.isEmpty) {
      setState(() => _uploadsConnectionStatus = 'Not configured');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      final ok = resp.statusCode < 500;
      setState(() => _uploadsConnectionStatus = ok ? 'OK' : 'Degraded');
    } catch (e) {
      setState(() => _uploadsConnectionStatus = 'Down');
    }
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

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MiskTheme.spacingMedium,
        vertical: MiskTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: MiskTheme.miskLightGreen.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: MiskTheme.miskLightGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: DesignTokens.weightSemiBold,
          color: MiskTheme.miskDarkGreen,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevron = false,
    Widget? statusBadge,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MiskTheme.miskGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: MiskTheme.miskDarkGreen,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: DesignTokens.weightMedium,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (statusBadge != null) ...[
            const SizedBox(height: 4),
            statusBadge,
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).dividerColor,
            ),
          ],
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MiskTheme.spacingMedium,
        vertical: MiskTheme.spacingSmall,
      ),
      minLeadingWidth: 48,
    );
  }

  Widget _buildUploadsStatusBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (_uploadsConnectionStatus) {
      case 'OK':
        badgeColor = SemanticColors.successGreen;
        badgeIcon = Icons.check_circle;
        break;
      case 'Degraded':
        badgeColor = SemanticColors.warningGold;
        badgeIcon = Icons.warning;
        break;
      case 'Down':
        badgeColor = SemanticColors.dangerRed;
        badgeIcon = Icons.error;
        break;
      case 'Disabled':
        badgeColor = SemanticColors.neutralGray;
        badgeIcon = Icons.block;
        break;
      default:
        badgeColor = SemanticColors.neutralGray;
        badgeIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            _uploadsConnectionStatus,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: DesignTokens.weightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRollupsStatusBadge() {
    if (_lastRunAt == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: SemanticColors.neutralGray.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Never run',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final runTime = _lastRunAt!.toDate();
    final duration = _lastRunMs ?? 0;
    final timeAgo = DateTime.now().difference(runTime);

    String timeAgoText;
    if (timeAgo.inDays > 0) {
      timeAgoText = '${timeAgo.inDays}d ago';
    } else if (timeAgo.inHours > 0) {
      timeAgoText = '${timeAgo.inHours}h ago';
    } else {
      timeAgoText = '${timeAgo.inMinutes}m ago';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last run: $timeAgoText (${duration}ms)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_lastRunBy != null)
          Text(
            'By: $_lastRunBy',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndRunRollups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recompute Roll-ups'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will recompute financial metrics for all initiatives.'),
            SizedBox(height: 8),
            Text('This operation may take several minutes.'),
            SizedBox(height: 8),
            Text('Continue?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runRollups();
    }
  }

  List<Map<String, dynamic>> get _allSettings {
    return [
      {
        'section': 'Access & Security',
        'items': [
          {
            'title': 'Roles & Permissions',
            'subtitle': 'Manage user roles and access controls',
            'icon': Icons.admin_panel_settings,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesListScreen())),
            'showChevron': true,
          },
          {
            'title': 'Security & App Lock',
            'subtitle': 'Configure app lock and security settings',
            'icon': Icons.security,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLockSettingsScreen())),
            'showChevron': true,
          },
        ],
      },
      {
        'section': 'Payments',
        'items': [
          {
            'title': 'Payment Providers / Bank Details',
            'subtitle': 'Configure payment gateways and bank accounts',
            'icon': Icons.payment,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
            'showChevron': true,
          },
        ],
      },
      {
        'section': 'Storage & Uploads',
        'items': [
          {
            'title': 'Uploads Backend',
            'subtitle': 'Configure file upload storage and settings',
            'icon': Icons.cloud_upload,
            'statusBadge': _buildUploadsStatusBadge(),
            'trailing': TextButton(
              onPressed: () => _pingUploads(context),
              child: const Text('Test'),
            ),
          },
        ],
      },
      {
        'section': 'Maintenance',
        'items': [
          {
            'title': 'Recompute Roll-ups',
            'subtitle': 'Recalculate financial metrics and aggregations',
            'icon': Icons.refresh,
            'statusBadge': _buildRollupsStatusBadge(),
            'trailing': _busyRollups
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _confirmAndRunRollups,
                    child: const Text('Run'),
                  ),
          },
        ],
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredSettings {
    final query = _search.text.toLowerCase().trim();
    if (query.isEmpty) return _allSettings;

    return _allSettings.map((section) {
      final filteredItems = (section['items'] as List<Map<String, dynamic>>)
          .where((item) =>
              item['title'].toString().toLowerCase().contains(query) ||
              item['subtitle'].toString().toLowerCase().contains(query))
          .toList();

      return {
        ...section,
        'items': filteredItems,
      };
    }).where((section) => (section['items'] as List).isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      // Access & Security section
      _buildSectionHeader('Access & Security'),
      _buildSettingsTile(
        title: 'Roles & Permissions',
        subtitle: 'Manage user roles and access controls',
        icon: Icons.admin_panel_settings,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesListScreen())),
        showChevron: true,
      ),
      _buildSettingsTile(
        title: 'Security & App Lock',
        subtitle: 'Configure app lock and security settings',
        icon: Icons.security,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLockSettingsScreen())),
        showChevron: true,
      ),
      // Payments section
      _buildSectionHeader('Payments'),
      _buildSettingsTile(
        title: 'Payment Providers / Bank Details',
        subtitle: 'Configure payment gateways and bank accounts',
        icon: Icons.payment,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
        showChevron: true,
      ),
      // Storage & Uploads section
      _buildSectionHeader('Storage & Uploads'),
      _buildSettingsTile(
        title: 'Uploads Backend',
        subtitle: 'Configure file upload storage and settings',
        icon: Icons.cloud_upload,
        statusBadge: _buildUploadsStatusBadge(),
        trailing: TextButton(
          onPressed: () => _pingUploads(context),
          child: const Text('Test'),
        ),
      ),
      // Maintenance section
      _buildSectionHeader('Maintenance'),
      _buildSettingsTile(
        title: 'Recompute Roll-ups',
        subtitle: 'Recalculate financial metrics and aggregations',
        icon: Icons.refresh,
        statusBadge: _buildRollupsStatusBadge(),
        trailing: _busyRollups
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _confirmAndRunRollups,
                child: const Text('Run'),
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
      appBar: widget.inShell ? null : AppBar(
        title: const Text('Global Settings'),
        leading: const BackOrHomeButton(),
      ),
      body: ListView(
        children: [
          const ContentHeader(title: 'Global Settings'),
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
