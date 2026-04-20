import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final content = _buildContent();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
    );
    switch (variant) {
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: shape,
          ),
          child: content,
        );
      case ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: shape,
          ),
          child: content,
        );
      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: shape,
          ),
          child: content,
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      default:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: shape,
          ),
          child: content,
        );
    }
  }

  Widget _buildContent() {
    final color = variant == ButtonVariant.outline ||
            variant == ButtonVariant.ghost
        ? AppColors.primary
        : AppColors.white;
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: _iconSize(), color: color),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: TextStyle(
                fontSize: _fontSize(),
                fontWeight: FontWeight.w600,
                color: color)),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: _iconSize(), color: color),
        ],
      ],
    );
  }

  double _height() {
    switch (size) {
      case ButtonSize.small: return 36;
      case ButtonSize.large: return 56;
      default: return 48;
    }
  }

  double _fontSize() {
    switch (size) {
      case ButtonSize.small: return 13;
      case ButtonSize.large: return 16;
      default: return 15;
    }
  }

  double _iconSize() {
    switch (size) {
      case ButtonSize.small: return 16;
      case ButtonSize.large: return 22;
      default: return 18;
    }
  }
}