import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/user_session.dart';
import '../../models/evidence_record.dart';
import '../../services/sync_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/forensic_metric_card.dart';
import '../../widgets/forensic_data_table.dart';
import '../../widgets/statutory_disclaimer_banner.dart';
import '../field_test/new_field_test_screen.dart';
import '../evidence/evidence_vault_screen.dart';
import '../evidence/test_history_screen.dart';
import '../evidence/evidence_detail_screen.dart';
import '../map/map_screen.dart';
import '../verification/integrity_verification_screen.dart';
import '../verification/audit_log_screen.dart';
import '../admin/admin_reference_profiles_screen.dart';
import '../authentication/login_screen.dart';

/// NEXORA Officer Forensic Dashboard
class OfficerDashboardScreen extends StatefulWidget {
  final UserSession session;

  const OfficerDashboardScreen({super.key, required this.session});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  List<EvidenceRecord> _records = [];
  bool _isLoading = true;
  int _pendingSyncCount = 0;
  String _chainIntegrityStatus = AppConstants.integrityVerified;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final all = await DatabaseHelper().getAllEvidence();
    final pending = await DatabaseHelper().getPendingSyncItems();
    final chain = await DatabaseHelper().getEvidenceChainChronological();
    
    // Quick chain check
    bool intact = true;
    for (int i = 0; i < chain.length; i++) {
      if (chain[i]['integrityStatus'] == AppConstants.integrityFailure) {
        intact = false;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _records = all;
        _pendingSyncCount = pending.length;
        _chainIntegrityStatus = intact ? AppConstants.integrityVerified : AppConstants.integrityFailure;
        _isLoading = false;
      });
    }
  }

  void _toggleConnectivity() {
    final current = SyncService().isOnline;
    SyncService().setOnlineStatus(!current);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SyncService().isOnline ? 'CONNECTIVITY RESTORED — SYNCING QUEUE' : 'OFFLINE MODE ENABLED',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        backgroundColor: SyncService().isOnline ? NexoraColors.verifiedGreen : NexoraColors.presumptiveAmber,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = SyncService().isOnline;

    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              '${widget.session.fullName} (${widget.session.badgeId}) • ${widget.session.role}',
              style: const TextStyle(
                fontSize: 10,
                color: NexoraColors.tacticalKhaki,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Online/Offline Pill Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            child: InkWell(
              onTap: _toggleConnectivity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? NexoraColors.verifiedGreen.withOpacity(0.2) : NexoraColors.alertRed.withOpacity(0.2),
                  border: Border.all(
                    color: isOnline ? NexoraColors.verifiedGreen : NexoraColors.alertRed,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? NexoraColors.verifiedGreen : NexoraColors.alertRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: NexoraColors.textMuted),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: NexoraColors.tacticalKhaki,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Offline Notice Banner if offline
              if (!isOnline) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: NexoraColors.cardDark,
                    border: Border.all(color: NexoraColors.presumptiveAmber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: NexoraColors.presumptiveAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline Mode — Records will synchronize automatically when connectivity is restored.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: NexoraColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Statutory Notice
              const StatutoryDisclaimerBanner(compact: true),

              const SizedBox(height: 16),

              // KPI Metric Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isWide ? 1.6 : 1.4,
                    children: [
                      ForensicMetricCard(
                        label: "TODAY'S TESTS",
                        value: '${_records.length}',
                        subValue: 'Logged to Vault',
                        icon: Icons.science_outlined,
                      ),
                      ForensicMetricCard(
                        label: 'PENDING SYNC',
                        value: '$_pendingSyncCount',
                        subValue: isOnline ? 'Auto-sync active' : 'Awaiting network',
                        icon: Icons.sync,
                        accentColor: _pendingSyncCount > 0 ? NexoraColors.presumptiveAmber : null,
                      ),
                      ForensicMetricCard(
                        label: 'INTEGRITY STATUS',
                        value: _chainIntegrityStatus.contains('VERIFIED') ? 'VERIFIED' : 'FAILURE',
                        subValue: 'SHA-256 Hash Chain',
                        icon: Icons.verified_user_outlined,
                        accentColor: _chainIntegrityStatus.contains('VERIFIED')
                            ? NexoraColors.verifiedGreen
                            : NexoraColors.alertRed,
                      ),
                      ForensicMetricCard(
                        label: 'ACTIVE CASES',
                        value: '${_records.map((r) => r.caseId).toSet().length}',
                        subValue: 'Assigned division',
                        icon: Icons.folder_open,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Primary Actions
              const Text(
                'COMMAND & FIELD ACTIONS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: NexoraColors.tacticalKhaki,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewFieldTestScreen(session: widget.session),
                        ),
                      );
                      _loadDashboardData();
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('NEW FIELD TEST'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EvidenceVaultScreen()),
                      );
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('EVIDENCE VAULT'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('TEST HISTORY'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('MAP EXPLORER'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const IntegrityVerificationScreen()),
                      );
                    },
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('VERIFY RECORD'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                      );
                    },
                    icon: const Icon(Icons.security, size: 18),
                    label: const Text('AUDIT LOG'),
                  ),
                  if (widget.session.isAdmin)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminReferenceProfilesScreen()),
                        );
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('ADMIN PROFILES'),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Field Evidence Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT FIELD EVIDENCE RECORDS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: NexoraColors.pureWhite,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.refresh, size: 14, color: NexoraColors.tacticalKhaki),
                    label: const Text(
                      'REFRESH',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.tacticalKhaki),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                  : ForensicDataTable(
                      records: _records.take(10).toList(),
                      onRecordSelected: (record) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EvidenceDetailScreen(record: record),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
