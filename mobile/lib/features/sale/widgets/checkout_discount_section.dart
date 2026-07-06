import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/price_format.dart';
import '../checkout_discount.dart';

class CheckoutDiscountSection extends StatefulWidget {
  const CheckoutDiscountSection({
    super.key,
    required this.subtotal,
    required this.onDiscountChanged,
    this.initialDiscount = const CheckoutDiscountInput(),
  });

  final double subtotal;
  final ValueChanged<CheckoutDiscountInput> onDiscountChanged;
  final CheckoutDiscountInput initialDiscount;

  @override
  State<CheckoutDiscountSection> createState() =>
      _CheckoutDiscountSectionState();
}

class _CheckoutDiscountSectionState extends State<CheckoutDiscountSection> {
  final _percent = TextEditingController();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _percent.text = _formatPercent(widget.initialDiscount.percent);
    _amount.text = formatDecimalInput(widget.initialDiscount.fixedAmount);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return formatDecimalInput(value);
  }

  @override
  void didUpdateWidget(covariant CheckoutDiscountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtotal != widget.subtotal) {
      _notify();
    }
    if (oldWidget.initialDiscount != widget.initialDiscount) {
      _percent.text = _formatPercent(widget.initialDiscount.percent);
      _amount.text = formatDecimalInput(widget.initialDiscount.fixedAmount);
      _notify();
    }
  }

  @override
  void dispose() {
    _percent.dispose();
    _amount.dispose();
    super.dispose();
  }

  CheckoutDiscountInput _currentInput() {
    return CheckoutDiscountInput(
      percent: parseDecimalInput(_percent.text) ?? 0,
      fixedAmount: parseDecimalInput(_amount.text) ?? 0,
    );
  }

  void _notify() {
    final input = _currentInput();
    final clampedFixed = input.fixedDiscountAmount(widget.subtotal);
    if (clampedFixed != input.fixedAmount) {
      _amount.text = formatDecimalInput(clampedFixed);
    }
    widget.onDiscountChanged(
      CheckoutDiscountInput(
        percent: input.percent,
        fixedAmount: clampedFixed,
      ),
    );
    setState(() {});
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'İndirim',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Önce % indirim, ardından kalan tutara tutar indirimi uygulanır.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _percent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _decoration('% indirim'),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _decoration('Tutar indirimi'),
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
