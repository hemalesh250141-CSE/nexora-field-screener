import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/reference_profile.dart';
import '../../widgets/status_indicator_badge.dart';

/// Admin Authorized Reference Profiles Management Screen
class AdminReferenceProfilesScreen extends StatefulWidget {
  const AdminReferenceProfilesScreen({super.key});

  @override
  State<AdminReferenceProfilesScreen> createState() => _AdminReferenceProfilesScreenState();
}

class _AdminReferenceProfilesScreenState extends State<AdminReferenceProfilesScreen> {
  List<ReferenceProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper().getAllProfiles();
    if (mounted) {
      setState(() {
        _profiles = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleProfile(ReferenceProfile profile) async {
    final updated = ReferenceProfile(
      profileId: profile.profileId,
      displayName: profile.displayName,
      category: profile.category,
      reagentName: profile.reagentName,
      functionalGroupTarget: profile.functionalGroupTarget,
      referenceHex: profile.referenceHex,
      referenceLab: profile.referenceLab,
      toleranceDeltaE: profile.toleranceDeltaE,
      version: profile.version,
      calibrationSource: profile.calibrationSource,
      active: !profile.active,
    );

    await DatabaseHelper().saveProfile(updated);
    _loadProfiles();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PROFILE ${profile.profileId} ${updated.active ? "ACTIVATED" : "DEACTIVATED"} (AUDIT EVENT LOGGED)',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        backgroundColor: updated.active ? NexoraColors.verifiedGreen : NexoraColors.presumptiveAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('ADMIN: REFERENCE PROFILES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadProfiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final prof = _profiles[idx];
                final color = Color(int.parse(prof.referenceHex.replaceAll('#', 'FF'), radix: 16));

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NexoraColors.cardDark,
                    border: Border.all(
                      color: prof.active ? NexoraColors.borderSubtle : NexoraColors.alertRed.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(color: NexoraColors.pureWhite, width: 1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                prof.profileId,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: NexoraColors.tacticalKhaki,
                                ),
                              ),
                            ],
                          ),
                          StatusIndicatorBadge(
                            status: prof.active ? 'ACTIVE' : 'DEACTIVATED',
                            small: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prof.displayName,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NexoraColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reagent: ${prof.reagentName} • Category: ${prof.category}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hex: ${prof.referenceHex} • L*: ${prof.referenceLab.l.toStringAsFixed(1)} a*: ${prof.referenceLab.a.toStringAsFixed(1)} b*: ${prof.referenceLab.b.toStringAsFixed(1)} • Max ΔE: ${prof.toleranceDeltaE}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _toggleProfile(prof),
                            icon: Icon(prof.active ? Icons.block : Icons.check, size: 14),
                            label: Text(prof.active ? 'DEACTIVATE PROFILE' : 'ACTIVATE PROFILE'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
