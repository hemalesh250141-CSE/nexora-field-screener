import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../models/user_session.dart';
import '../../widgets/statutory_disclaimer_banner.dart';
import 'camera_screen.dart';

/// Step 1 of Field Testing Workflow: Case ID & Reagent Selection
class NewFieldTestScreen extends StatefulWidget {
  final UserSession session;

  const NewFieldTestScreen({super.key, required this.session});

  @override
  State<NewFieldTestScreen> createState() => _NewFieldTestScreenState();
}

class _NewFieldTestScreenState extends State<NewFieldTestScreen> {
  final _caseIdController = TextEditingController(text: 'CASE-2026-0891');
  final _notesController = TextEditingController();

  String _selectedReagent = 'Marquis Reagent';

  final List<String> _authorizedReagents = [
    'Marquis Reagent',
    'Mecke Reagent',
    'Mandelin Reagent',
    'Froehde Reagent',
    'Ehrlich Reagent',
    "Simon's (A + B)",
    'Scott Reagent (Cobalt Thiocyanate)',
    'Duquenois-Levine Reagent',
  ];

  void _proceedToCamera() {
    final caseId = _caseIdController.text.trim();
    if (caseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case ID is required for chain of custody.'),
          backgroundColor: NexoraColors.alertRed,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          session: widget.session,
          caseId: caseId,
          reagentUsed: _selectedReagent,
          officerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('NEW FIELD TEST — STEP 1 OF 3'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatutoryDisclaimerBanner(compact: true),
            const SizedBox(height: 16),

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
                    'FORENSIC CHAIN IDENTIFICATION',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _caseIdController,
                    decoration: const InputDecoration(
                      labelText: 'CASE FILE NUMBER / INCIDENT ID',
                      hintText: 'e.g. CASE-2026-0891',
                      prefixIcon: Icon(Icons.folder_open, color: NexoraColors.tacticalKhaki, size: 18),
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'PRESUMPTIVE SPOT REAGENT USED',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NexoraColors.textSecondary,
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
                        value: _selectedReagent,
                        isExpanded: true,
                        dropdownColor: NexoraColors.cardDark,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: NexoraColors.pureWhite),
                        items: _authorizedReagents.map((reagent) {
                          return DropdownMenuItem(
                            value: reagent,
                            child: Text(reagent),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReagent = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'FIELD OBSERVATIONS & MATRIX NOTES (OPTIONAL)',
                      hintText: 'e.g. Crystalline powder, ambient temp 28C, sample pouch sealed.',
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Operator identity display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin, color: NexoraColors.tacticalKhaki, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECORDING OFFICER',
                          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: NexoraColors.textMuted),
                        ),
                        Text(
                          '${widget.session.fullName} • BADGE ID: ${widget.session.badgeId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NexoraColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _proceedToCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('PROCEED TO DUAL-TARGET CAMERA CAPTURE'),
            ),
          ],
        ),
      ),
    );
  }
}
