import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/core/utils/dimensions.dart';

/// A custom service tag input widget with specific formatting: [3 digits] [space] [4 digits]
/// Example: [M][N][T] [A][0][0][1]
/// All input is converted to uppercase alphanumeric characters.
class ServiceTagInput extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const ServiceTagInput({
    super.key,
    this.controller,
    this.onChanged,
    this.validator,
  });

  @override
  State<ServiceTagInput> createState() => _ServiceTagInputState();
}

class _ServiceTagInputState extends State<ServiceTagInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    String text = _controller.text.replaceAll(' ', '').toUpperCase();
    
    // Keep only alphanumeric characters
    text = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Limit to 7 characters total
    if (text.length > 7) {
      text = text.substring(0, 7);
    }

    // Format as [3] [4]
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    // Only update if the formatted text is different
    if (formatted != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
        composing: TextRange.empty,
      );
    }

    widget.onChanged?.call(text); // Return unformatted version for data
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Tag',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
          ],
          validator: widget.validator,
          maxLength: 8, // 7 chars + 1 space
          decoration: InputDecoration(
            hintText: 'MNT A001',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceDim,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            counterText: '', // Hide character counter
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                letterSpacing: 4.0,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
