import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/evidence_record.dart';
import '../../services/location_service.dart';
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
  GpsLocationResult? _currentLocation;
  String? _locationError;
  bool _isLoading = true;
  bool _mapReady = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'markerSelected',
        onMessageReceived: (message) {
          final record = _records.where((item) => item.id == message.message).firstOrNull;
          if (record != null && mounted) setState(() => _selectedRecord = record);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _mapReady = true;
            _renderMap();
          },
        ),
      )
      ..loadFlutterAsset('assets/leaflet_map.html');
    _loadLocations();
    _findDeviceLocation(moveMap: false);
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
      _renderMap();
    }
  }

  Future<void> _findDeviceLocation({bool moveMap = true}) async {
    final result = await LocationService().getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentLocation = result.isAvailable ? result : null;
      _locationError = result.isAvailable ? null : result.notice;
    });
    if (result.isAvailable && moveMap) _renderMap(recenter: true);
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }

  Future<void> _renderMap({bool recenter = false}) async {
    if (!_mapReady) return;
    final validRecords = _records.where((record) {
      return _isValidCoordinate(record.gpsLatitude, record.gpsLongitude);
    }).map((record) => {
      'id': record.id,
      'caseId': record.caseId,
      'status': record.analysisStatus,
      'latitude': record.gpsLatitude,
      'longitude': record.gpsLongitude,
      'accuracy': record.gpsAccuracy,
    }).toList();
    final current = _currentLocation == null
        ? null
        : {
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
            'accuracy': _currentLocation!.accuracyMeters,
          };
    await _webViewController.runJavaScript(
      'window.updateEvidence(${jsonEncode(validRecords)}, ${jsonEncode(current)}, $recenter);',
    );
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
            IconButton(
              icon: const Icon(Icons.my_location, size: 20),
              tooltip: 'Find my location',
              onPressed: () => _findDeviceLocation(),
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

                if (_locationError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    color: NexoraColors.cardDark,
                    child: Text(
                      _locationError!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.presumptiveAmber),
                    ),
                  ),

                Expanded(
                  child: WebViewWidget(controller: _webViewController),
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
