import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/evidence_record.dart';
import '../../widgets/status_indicator_badge.dart';
import '../evidence/evidence_detail_screen.dart';

/// NEXORA Forensic Map Screen
/// Displays geographic distribution of field presumptive tests with marker inspector.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<EvidenceRecord> _records = [];
  EvidenceRecord? _selectedRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    final all = await DatabaseHelper().getAllEvidence();
    if (mounted) {
      setState(() {
        _records = all;
        if (all.isNotEmpty) _selectedRecord = all.first;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('FORENSIC INCIDENT MAP EXPLORER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Map Telemetry Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: NexoraColors.cardDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE FIELD LOCATIONS: ${_records.length}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NexoraColors.tacticalKhaki,
                        ),
                      ),
                      const Text(
                        'WGS84 PROJECTION • NATIVE GPS',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                      ),
                    ],
                  ),
                ),

                // Interactive Simulated Tactical Map Canvas
                Expanded(
                  child: Stack(
                    children: [
                      // Dark Tactical Map Grid Canvas
                      Container(
                        color: const Color(0xFF0F141C),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _TacticalMapPainter(),
                        ),
                      ),

                      // Location Pins on Map
                      if (_records.isEmpty)
                        const Center(
                          child: Text(
                            'NO GEOTAGGED TESTS RECORDED',
                            style: TextStyle(fontFamily: 'monospace', color: NexoraColors.textMuted),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: _records.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final rec = entry.value;
                                final isSelected = _selectedRecord?.id == rec.id;

                                // Spread coordinates across the canvas nicely for demonstration
                                final xOffset = (constraints.maxWidth * 0.2) + ((idx * 85) % (constraints.maxWidth * 0.6));
                                final yOffset = (constraints.maxHeight * 0.2) + ((idx * 65) % (constraints.maxHeight * 0.5));

                                final pinColor = rec.analysisStatus == 'PRESUMPTIVE'
                                    ? NexoraColors.presumptiveAmber
                                    : NexoraColors.inconclusiveGray;

                                return Positioned(
                                  left: xOffset,
                                  top: yOffset,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedRecord = rec);
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: NexoraColors.classicBlack,
                                            border: Border.all(
                                              color: isSelected ? NexoraColors.tacticalKhaki : pinColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            rec.id,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? NexoraColors.tacticalKhaki : NexoraColors.pureWhite,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.location_on,
                                          color: pinColor,
                                          size: isSelected ? 32 : 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // Marker Inspector Bottom Sheet
                if (_selectedRecord != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NexoraColors.cardDark,
                      border: const Border(top: BorderSide(color: NexoraColors.tacticalKhaki, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TEST ID: ${_selectedRecord!.id}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: NexoraColors.pureWhite,
                                  ),
                                ),
                                Text(
                                  'Case: ${_selectedRecord!.caseId} • Officer: ${_selectedRecord!.officerId}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: NexoraColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            StatusIndicatorBadge(status: _selectedRecord!.analysisStatus),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'COORDINATES: ${_selectedRecord!.gpsLatitude.toStringAsFixed(5)}, ${_selectedRecord!.gpsLongitude.toStringAsFixed(5)} (±${_selectedRecord!.gpsAccuracy.toStringAsFixed(1)}m)',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                        ),
                        Text(
                          'TIMESTAMP: ${_selectedRecord!.capturedAtUtc}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusIndicatorBadge(status: _selectedRecord!.integrityStatus, small: true),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EvidenceDetailScreen(record: _selectedRecord!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 14),
                              label: const Text('INSPECT EVIDENCE'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TacticalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.5)
      ..strokeWidth = 1.0;

    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Concentric coordinate rings
    final ringPaint = Paint()
      ..color = NexoraColors.tacticalKhaki.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 90, ringPaint);
    canvas.drawCircle(center, 180, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
