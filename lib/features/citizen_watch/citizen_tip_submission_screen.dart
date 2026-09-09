import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/citizen_tip.dart';
import 'submission_confirmation_screen.dart';

/// Anonymous Citizen Tip Submission Form
class CitizenTipSubmissionScreen extends StatefulWidget {
  const CitizenTipSubmissionScreen({super.key});

  @override
  State<CitizenTipSubmissionScreen> createState() => _CitizenTipSubmissionScreenState();
}

class _CitizenTipSubmissionScreenState extends State<CitizenTipSubmissionScreen> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Suspicious Packaging / Drop';
  bool _shareLocation = true;
  bool _hasMediaAttached = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Suspicious Packaging / Drop',
    'Unidentified Chemical Odor',
    'Abandoned Hazardous Container',
    'Repeated Vehicle Exchange Activity',
    'Suspected Unlicensed Chemical Storage',
    'General Community Safety Observation',
  ];

  Future<void> _submitTip() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a brief description of the observation.'),
          backgroundColor: NexoraColors.alertRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Generate random anonymous receipt ID
    final randomId = 'TIP-2026-${math.Random().nextInt(900000) + 100000}';
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    final tip = CitizenTip(
      tipId: randomId,
      category: _selectedCategory,
      description: desc,
      optionalLatitude: _shareLocation ? 13.0827 : null,
      optionalLongitude: _shareLocation ? 80.2707 : null,
      optionalMediaHash: _hasMediaAttached ? 'SHA256_MOCK_ATTACHMENT_${DateTime.now().millisecondsSinceEpoch}' : null,
      submittedAtUtc: nowUtc,
      status: 'SUBMITTED',
    );

    await DatabaseHelper().insertCitizenTip(tip);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SubmissionConfirmationScreen(tip: tip),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('SUBMIT ANONYMOUS TIP'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIP CLASSIFICATION',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: NexoraColors.classicBlack,
                      border: Border.all(color: NexoraColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: NexoraColors.cardDark,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: NexoraColors.pureWhite),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'OBSERVATION DETAILS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you observed, location landmarks, time of occurrence, or packaging appearance...',
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),

                  const SizedBox(height: 16),

                  // Location Toggle
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: const Text(
                        'INCLUDE APPROXIMATE LOCATION',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Attaches generalized GPS sector coordinates without revealing personal device telemetry.',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                      ),
                      value: _shareLocation,
                      activeColor: NexoraColors.tacticalKhaki,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _shareLocation = v),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Media Attachment Mock
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _hasMediaAttached = !_hasMediaAttached);
                    },
                    icon: Icon(_hasMediaAttached ? Icons.check_circle : Icons.attach_file, size: 16),
                    label: Text(
                      _hasMediaAttached ? 'ATTACHMENT ENCRYPTED & STAGED' : 'ATTACH PHOTO / DOCUMENTATION (OPTIONAL)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTip,
              child: _isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('TRANSMIT ANONYMOUS TIP SECURELY'),
            ),
          ],
        ),
      ),
    );
  }
}
