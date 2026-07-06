import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9999,
    this.compact = false,
    this.allowDirectInput = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;
  final bool allowDirectInput;

  @override
  State<QuantityStepper> createState() => QuantityStepperState();
}

class QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _inputController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _inputController.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitInput();
    }
  }

  void _commitInput() {
    final parsed = int.tryParse(_inputController.text.trim());
    if (parsed == null) {
      _inputController.text = '${widget.value}';
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max);
    _inputController.text = '$clamped';
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  /// Applies a typed value before reading (e.g. dialog confirm).
  int ensureCommitted() {
    final parsed = int.tryParse(_inputController.text.trim());
    if (parsed == null) {
      _inputController.text = '${widget.value}';
      return widget.value;
    }
    final clamped = parsed.clamp(widget.min, widget.max);
    _inputController.text = '$clamped';
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
    return clamped;
  }

  void _step(int delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    _inputController.text = '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonSize = widget.compact ? 30.0 : 36.0;
    final valueWidth = widget.allowDirectInput
        ? (widget.compact ? 48.0 : 64.0)
        : (widget.compact ? 28.0 : 36.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(widget.compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: widget.value > widget.min,
            size: buttonSize,
            iconSize: widget.compact ? 16 : 18,
            onTap: () => _step(-1),
          ),
          Container(
            width: valueWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: widget.allowDirectInput
                ? TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: widget.compact ? 13 : null,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _commitInput(),
                  )
                : Text(
                    '${widget.value}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: widget.compact ? 13 : null,
                    ),
                  ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: widget.value < widget.max,
            size: buttonSize,
            iconSize: widget.compact ? 16 : 18,
            onTap: () => _step(1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: iconSize,
        visualDensity: VisualDensity.compact,
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
      ),
    );
  }
}
