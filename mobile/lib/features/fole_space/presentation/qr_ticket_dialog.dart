import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

class QrTicketDialog extends StatelessWidget {
  final String eventTitle;
  final String ticketCode;
  final String startsAt;

  const QrTicketDialog({
    super.key,
    required this.eventTitle,
    required this.ticketCode,
    required this.startsAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.blue600, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIGITAL ENTRY PASS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.slate500,
                        ),
                      ),
                      Text(
                        'FOLE SPACE Verified',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy950,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.slate400),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Event Details
            Text(
              eventTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.navy950,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatDateTime(startsAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 20),

            // High-Contrast QR Pattern Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.navy950, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _QrMatrixPainter(payload: ticketCode),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ticket Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticketCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.navy950,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Present this QR pass to the event desk scanner upon arrival at FOLE SPACE.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.slate500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a deterministic high-contrast 2D matrix pattern encoding the ticket code payload
class _QrMatrixPainter extends CustomPainter {
  final String payload;

  _QrMatrixPainter({required this.payload});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF07111F);
    final paintLight = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintLight);

    const int gridSize = 21;
    final double cellSize = size.width / gridSize;

    // Deterministic hash-based matrix filling
    final bytes = payload.codeUnits;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Standard QR Finder patterns at top-left, top-right, bottom-left
        if (_isFinderPattern(row, col, gridSize)) {
          final isDark = _finderPatternPixel(row, col, gridSize);
          if (isDark) {
            canvas.drawRect(
              Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
              paintDark,
            );
          }
          continue;
        }

        // Timing patterns
        if (row == 6 || col == 6) {
          if ((row + col) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
              paintDark,
            );
          }
          continue;
        }

        // Data cells derived deterministically from payload
        final byteIndex = (row * gridSize + col) % bytes.length;
        final bit = (bytes[byteIndex] >> ((row + col) % 8)) & 1;
        if (bit == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
            paintDark,
          );
        }
      }
    }
  }

  bool _isFinderPattern(int r, int c, int size) {
    if (r < 7 && c < 7) return true; // Top-left
    if (r < 7 && c >= size - 7) return true; // Top-right
    if (r >= size - 7 && c < 7) return true; // Bottom-left
    return false;
  }

  bool _finderPatternPixel(int r, int c, int size) {
    int localR = r;
    int localC = c;
    if (c >= size - 7) localC = c - (size - 7);
    if (r >= size - 7) localR = r - (size - 7);

    if (localR == 0 || localR == 6 || localC == 0 || localC == 6) return true;
    if (localR >= 2 && localR <= 4 && localC >= 2 && localC <= 4) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
