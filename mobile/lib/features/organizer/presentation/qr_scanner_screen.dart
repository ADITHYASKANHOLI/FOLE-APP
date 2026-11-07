import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../data/organizer_repository.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String eventId;

  const QrScannerScreen({super.key, required this.eventId});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _processTicketCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(organizerRepositoryProvider);
      final res = await repo.scanQrCheckin(widget.eventId, cleanCode);

      if (mounted) {
        _showSuccessDialog(
          attendeeUsername: res.studentUsername ?? 'Student',
          message: res.message,
        );
        ref.invalidate(organizerDeskProvider(widget.eventId));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog({
    required String attendeeUsername,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded,
            color: AppColors.successGreen, size: 48),
        title: const Text('Check-In Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '@$attendeeUsername',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy950,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.slate600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _manualCodeController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Next Scan'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded,
            color: AppColors.errorRed, size: 48),
        title: const Text('Check-In Failed'),
        content: Text(
          errorMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.slate700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy950,
      appBar: const EngivaultAppBar(
        title: 'Ticket Scanner',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scanner Viewport Frame
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewport background
                  Container(
                    color: Colors.black,
                  ),

                  // Target Box Frame
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cyan400, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 64,
                            color: AppColors.cyan400.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Align QR code within frame',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.cyan400),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Manual Code Entry Fallback
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Manual Ticket Verification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy950,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter ticket code if attendee screen is cracked or dim',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. FS1.aB3_x9Z0-123456',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onSubmitted: (code) => _processTicketCode(code),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () =>
                                _processTicketCode(_manualCodeController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
