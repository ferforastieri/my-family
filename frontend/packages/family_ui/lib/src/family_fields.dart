import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FamilySelectOption<T> {
  const FamilySelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

class FamilyTextField extends StatelessWidget {
  const FamilyTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.decoration,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.autovalidateMode,
    this.onSaved,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.expands = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.focusNode,
    this.onTap,
    this.onEditingComplete,
    this.scrollPadding = const EdgeInsets.all(20),
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final InputDecoration? decoration;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final void Function(String?)? onSaved;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool expands;
  final TextStyle? style;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final EdgeInsets scrollPadding;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onSaved: onSaved,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      expands: expands,
      style: style,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      scrollPadding: scrollPadding,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofocus: autofocus,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
    );
  }
}

class FamilySelect<T> extends StatelessWidget {
  const FamilySelect({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.enabled = true,
  });

  final List<FamilySelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, hintText: hint),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option.value,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class FamilyDatePicker {
  const FamilyDatePicker._();

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(now.year + 20),
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class FamilyDateField extends StatelessWidget {
  const FamilyDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Selecionar data'
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/'
            '${value!.year}';
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await FamilyDatePicker.show(
                context,
                initialDate: value,
                firstDate: firstDate,
                lastDate: lastDate,
                helpText: label,
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(formatted),
      ),
    );
  }
}
