import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SignupStepper extends StatelessWidget {
  const SignupStepper({super.key, required this.currentStep});

  /// Zero-based index into [steps].
  final int currentStep;

  static const steps = ['Personal', 'School', 'Account', 'Verify', 'Complete'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow screens only the current step keeps its label.
        final showAllLabels = constraints.maxWidth > 460;
        return Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: i <= currentStep ? AppColors.orange : AppColors.border,
                  ),
                ),
              _StepItem(
                number: i + 1,
                label: steps[i],
                reached: i <= currentStep,
                isCurrent: i == currentStep,
                showLabel: showAllLabels || i == currentStep,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.label,
    required this.reached,
    required this.isCurrent,
    required this.showLabel,
  });

  final int number;
  final String label;
  final bool reached;
  final bool isCurrent;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: reached ? AppColors.orange : Colors.white,
            shape: BoxShape.circle,
            border: reached ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: reached ? Colors.white : AppColors.muted,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              color: reached ? AppColors.orange : AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}
