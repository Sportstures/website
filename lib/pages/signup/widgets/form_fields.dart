import 'package:flutter/material.dart';

import '../signup_theme.dart';

String? requiredValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Required' : null;

InputDecoration _inputDecoration({
  String? hint,
  required Color borderColor,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: SignupColors.hint, fontSize: 13),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: suffixIcon,
    enabledBorder: border(borderColor),
    focusedBorder: border(SignupColors.orange, 1.5),
    errorBorder: border(Colors.red.shade400),
    focusedErrorBorder: border(Colors.red.shade400, 1.5),
  );
}

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: SignupColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: SignupColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SignupColors.text,
        ),
      ),
    );
  }
}

class SignupTextField extends StatefulWidget {
  const SignupTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.isPassword = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool isPassword;

  @override
  State<SignupTextField> createState() => _SignupTextFieldState();
}

class _SignupTextFieldState extends State<SignupTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          style: const TextStyle(fontSize: 13, color: SignupColors.text),
          decoration: _inputDecoration(
            hint: widget.hint,
            borderColor: SignupColors.orange.withValues(alpha: 0.6),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: SignupColors.muted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}

class SignupDropdown<T> extends StatelessWidget {
  const SignupDropdown({
    super.key,
    this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.itemLabel,
    this.validator,
  });

  final String? label;
  final String hint;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabel;

  /// Defaults to requiring a selection.
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(color: SignupColors.hint, fontSize: 13)),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: SignupColors.muted),
      style: const TextStyle(fontSize: 13, color: SignupColors.text),
      borderRadius: BorderRadius.circular(8),
      dropdownColor: Colors.white,
      decoration: _inputDecoration(borderColor: SignupColors.border),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(itemLabel?.call(item) ?? '$item', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: validator ?? (v) => v == null ? 'Required' : null,
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(label!), field],
    );
  }
}
