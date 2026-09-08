import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/evidence_record.dart';
import '../../widgets/forensic_data_table.dart';
import 'evidence_detail_screen.dart';

/// Secure Searchable Evidence Vault Screen
class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> {
  final _searchController = TextEditingController();
  List<EvidenceRecord> _allRecords = [];
  List<EvidenceRecord> _filteredRecords = [];
  bool _isLoading = true;

  String _selectedStatusFilter = 'ALL';
  String _selectedSyncFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper().getAllEvidence();
    if (mounted) {
      setState(() {
        _allRecords = list;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredRecords = _allRecords.where((rec) {
        // Query match
        final matchesQuery = query.isEmpty ||
            rec.id.toLowerCase().contains(query) ||
            rec.caseId.toLowerCase().contains(query) ||
            rec.officerId.toLowerCase().contains(query) ||
            rec.evidenceHash.toLowerCase().contains(query);

        // Status match
        final matchesStatus = _selectedStatusFilter == 'ALL' ||
            rec.analysisStatus.toUpperCase() == _selectedStatusFilter;

        // Sync match
        final matchesSync = _selectedSyncFilter == 'ALL' ||
            rec.syncStatus.toUpperCase() == _selectedSyncFilter;

        return matchesQuery && matchesStatus && matchesSync;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('SECURE EVIDENCE VAULT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadVault,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by Case ID, Test ID, Officer Badge, or Hash...',
                prefixIcon: const Icon(Icons.search, color: NexoraColors.tacticalKhaki, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),

            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'RESULT: ',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                  _filterChip('ALL', _selectedStatusFilter, (v) {
                    setState(() => _selectedStatusFilter = v);
                    _applyFilters();
                  }),
                  const SizedBox(width: 6),
                  _filterChip('PRESUMPTIVE', _selectedStatusFilter, (v) {
                    setState(() => _selectedStatusFilter = v);
                    _applyFilters();
                  }),
                  const SizedBox(width: 6),
                  _filterChip('INCONCLUSIVE', _selectedStatusFilter, (v) {
                    setState(() => _selectedStatusFilter = v);
                    _applyFilters();
                  }),
                  const SizedBox(width: 14),
                  const Text(
                    'SYNC: ',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                  _filterChip('ALL', _selectedSyncFilter, (v) {
                    setState(() => _selectedSyncFilter = v);
                    _applyFilters();
                  }),
                  const SizedBox(width: 6),
                  _filterChip('SYNCED', _selectedSyncFilter, (v) {
                    setState(() => _selectedSyncFilter = v);
                    _applyFilters();
                  }),
                  const SizedBox(width: 6),
                  _filterChip('PENDING_SYNC', _selectedSyncFilter, (v) {
                    setState(() => _selectedSyncFilter = v);
                    _applyFilters();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Header summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MATCHES: ${_filteredRecords.length} / ${_allRecords.length} RECORDS',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NexoraColors.tacticalKhaki,
                  ),
                ),
                const Text(
                  'APPEND-ONLY IMMUTABLE STORE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: NexoraColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Evidence Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ForensicDataTable(
                      records: _filteredRecords,
                      onRecordSelected: (record) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EvidenceDetailScreen(record: record),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String current, Function(String) onSelected) {
    final isSelected = current == label;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
      selected: isSelected,
      selectedColor: NexoraColors.tacticalKhaki,
      backgroundColor: NexoraColors.cardDark,
      side: const BorderSide(color: NexoraColors.borderSubtle),
      labelStyle: TextStyle(
        color: isSelected ? NexoraColors.textInverse : NexoraColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onSelected(label),
    );
  }
}
