import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class UrineCheckerSheet extends StatefulWidget {
  const UrineCheckerSheet({super.key});

  @override
  State<UrineCheckerSheet> createState() => _UrineCheckerSheetState();
}

class _UrineCheckerSheetState extends State<UrineCheckerSheet> {
  UrineColor? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Hydration check 💛',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Tap the color that matches yours',
              style:
                  TextStyle(fontSize: 13, color: context.textSecondary)),
          const SizedBox(height: 24),

          // Color scale
          Row(
            children: urineColorScale.map((uc) {
              final isSel = _selected?.index == uc.index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = uc);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: isSel ? 64 : 52,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: uc.color,
                      borderRadius: BorderRadius.circular(10),
                      border: isSel
                          ? Border.all(
                              color: context.textPrimary, width: 2.5)
                          : null,
                    ),
                    child: isSel
                        ? const Center(
                            child: Icon(Icons.check,
                                color: Colors.black54, size: 18))
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Well hydrated',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600)),
                Text('Dehydrated',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600)),
              ]),

          const SizedBox(height: 24),

          // Result
          if (_selected == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: context.pageBg,
                  borderRadius: BorderRadius.circular(18)),
              child: Center(
                child: Text('Tap a color to see your result',
                    style: TextStyle(color: context.textSecondary)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selected!.needsWater
                    ? AppTheme.danger.withOpacity(0.07)
                    : AppTheme.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _selected!.needsWater
                      ? AppTheme.danger.withOpacity(0.3)
                      : AppTheme.success.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: _selected!.color,
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _selected!.needsWater
                                        ? AppTheme.danger
                                        : AppTheme.success)),
                            const SizedBox(height: 4),
                            Text(_selected!.message,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: context.textSecondary)),
                            if (_selected!.needsWater) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () =>
                                    Navigator.pop(context),
                                icon: const Icon(Icons.water_drop,
                                    size: 16),
                                label:
                                    const Text('Log water now'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ]),
                    ),
                  ]),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
