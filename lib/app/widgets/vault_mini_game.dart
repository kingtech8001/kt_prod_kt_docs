import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_scan_result.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/vault_mini_game_controller.dart';

class VaultMiniGameWidget extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback? onContinueToForm;
  final RxBool isScanning;
  final Rxn<DocumentScanResult> scanResult;
  final RxInt autoFilledFieldsCount;

  const VaultMiniGameWidget({
    super.key,
    required this.onDismiss,
    this.onContinueToForm,
    required this.isScanning,
    required this.scanResult,
    required this.autoFilledFieldsCount,
  });

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<VaultMiniGameController>();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.keyA) {
            gameController.moveLeft();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.keyD) {
            gameController.moveRight();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark Slate
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar: Game Title, Scan Status, Score & Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🎮', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vault Doc Catcher',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Catch falling documents & keys with your vault shield',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score & Close Button
                  Obx(
                    () => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            'Score: ${gameController.score.value}',
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          tooltip: 'Close Game',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Get.delete<VaultMiniGameController>();
                            onDismiss();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Play Arena
            LayoutBuilder(
              builder: (context, constraints) {
                final arenaWidth = constraints.maxWidth;
                const arenaHeight = 200.0;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final normalized = details.localPosition.dx / arenaWidth;
                    gameController.setPlayerPosition(normalized);
                  },
                  onTapDown: (details) {
                    final normalized = details.localPosition.dx / arenaWidth;
                    gameController.setPlayerPosition(normalized);
                  },
                  child: Container(
                    height: arenaHeight,
                    width: double.infinity,
                    color: const Color(0xFF090D16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Grid lines
                        Positioned.fill(
                          child: CustomPaint(painter: _GridPainter()),
                        ),

                        // Score Pop Effect
                        Obx(() {
                          final effect = gameController.catchEffectEmoji.value;
                          if (effect.isEmpty) return const SizedBox.shrink();
                          return Positioned(
                            bottom: 50,
                            left:
                                (gameController.playerX.value * arenaWidth) -
                                30,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 0.95,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  effect,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Falling Items
                        Obx(() {
                          return Stack(
                            children: gameController.items.map((item) {
                              return Positioned(
                                left: (item.x * arenaWidth) - 14,
                                top: item.y * arenaHeight,
                                child: Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              );
                            }).toList(),
                          );
                        }),

                        // Player Basket / Vault Shield
                        Obx(() {
                          final px = gameController.playerX.value;
                          return Positioned(
                            bottom: 12,
                            left: (px * arenaWidth) - 36,
                            child: Container(
                              width: 72,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF38BDF8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF38BDF8,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'VAULT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Controls & Direction Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    color: Colors.white70,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: gameController.moveLeft,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    color: Colors.white70,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: gameController.moveRight,
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      Get.delete<VaultMiniGameController>();
                      onDismiss();
                    },
                    child: const Text(
                      'Close Game ✕',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Green Scan Complete Message Banner BELOW the Game with Action Buttons
            Obx(() {
              final scanning = isScanning.value;
              final result = scanResult.value;
              final fields = autoFilledFieldsCount.value;

              if (scanning || result == null) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B), // Deep Emerald
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF34D399),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Document Scanned & Extracted!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$fields fields filled',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Identified as: ${result.detectedCategoryName} (${result.detectedSubcategory})',
                                style: const TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (result.vehicleFields['vehicleNumber'] != null ||
                        result.documentNumber != null ||
                        (result.amount != null && result.amount! > 0)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (result.vehicleFields['vehicleNumber'] != null &&
                              result.vehicleFields['vehicleNumber']
                                  .toString()
                                  .isNotEmpty)
                            _buildDetailChip(
                              '🚗 Reg',
                              result.vehicleFields['vehicleNumber'].toString(),
                            ),
                          if (result.documentNumber != null &&
                              result.documentNumber!.isNotEmpty)
                            _buildDetailChip(
                              '📄 Doc/Policy #',
                              result.documentNumber!,
                            ),
                          if (result.amount != null && result.amount! > 0)
                            _buildDetailChip(
                              '💰 Amount',
                              '₹${result.amount!.toStringAsFixed(2)}',
                            ),
                          if (result.secondaryDate != null)
                            _buildDetailChip(
                              '📅 Due/Expiry',
                              '${result.secondaryDate!.day.toString().padLeft(2, '0')}/${result.secondaryDate!.month.toString().padLeft(2, '0')}/${result.secondaryDate!.year}',
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Action Buttons below the green message
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: const Text(
                            'Play Again 🕹️',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            side: const BorderSide(color: Color(0xFF475569)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            gameController.startGame();
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                          ),
                          label: const Text(
                            'View Extracted Form ➔',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            Get.delete<VaultMiniGameController>();
                            if (onContinueToForm != null) {
                              onContinueToForm!();
                            } else {
                              onDismiss();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
