import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class AddDrinkSheet extends StatefulWidget {
  final WidgetRef ref;
  const AddDrinkSheet({super.key, required this.ref});

  @override
  State<AddDrinkSheet> createState() => _AddDrinkSheetState();
}

class _AddDrinkSheetState extends State<AddDrinkSheet> {
  DrinkType _type = DrinkType.water;
  int _amount = 250;
  bool _showCustom = false;
  final _customCtrl = TextEditingController();
  final _presets = [100, 150, 200, 250, 300, 350, 400, 500];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int get _finalAmount {
    if (_showCustom) return int.tryParse(_customCtrl.text) ?? _amount;
    return _amount;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.93,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a drink',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Caffeine reduces effective hydration',
                        style: TextStyle(
                            fontSize: 13, color: context.textSecondary)),
                    const SizedBox(height: 24),

                    // Drink type grid
                    Text('Type',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                      children: DrinkType.values.map((t) {
                        final sel = _type == t;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _type = t);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : context.pageBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primary
                                    : context.divider,
                                width: sel ? 2 : 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t.emoji,
                                    style:
                                        const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(t.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? AppTheme.primary
                                            : context.textSecondary)),
                                if (t.caffeineOffset > 0)
                                  Text('+${t.caffeineOffset}ml demand',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.warning,
                                          fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Amount
                    Text('Amount',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._presets.map((ml) {
                          final sel = !_showCustom && _amount == ml;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _amount = ml;
                              _showCustom = false;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primary
                                    : context.pageBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel
                                        ? AppTheme.primary
                                        : context.divider,
                                    width: 0.5),
                              ),
                              child: Text('${ml}ml',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: sel
                                          ? Colors.white
                                          : context.textPrimary)),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showCustom = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _showCustom
                                  ? AppTheme.accent.withOpacity(0.1)
                                  : context.pageBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _showCustom
                                      ? AppTheme.accent
                                      : context.divider,
                                  width: _showCustom ? 1.5 : 0.5),
                            ),
                            child: Text('Custom',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _showCustom
                                        ? AppTheme.accent
                                        : context.textSecondary)),
                          ),
                        ),
                      ],
                    ),

                    if (_showCustom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Amount in ml',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: context.pageBg,
                        ),
                      ),
                    ],

                    if (_type.caffeineOffset > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3),
                              width: 0.5),
                        ),
                        child: Row(children: [
                          const Text('☕',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_type.label} adds ${_type.caffeineOffset}ml extra demand. Only ${(_finalAmount * _type.hydrationFactor).toInt()}ml counts toward hydration.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final amt = _finalAmount;
                          if (amt <= 0) return;
                          HapticFeedback.mediumImpact();
                          widget.ref
                              .read(entriesProvider.notifier)
                              .addEntry(amountMl: amt, drinkType: _type);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Add ${_type.emoji} ${_finalAmount}ml',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
