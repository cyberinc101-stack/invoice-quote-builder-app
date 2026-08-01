// lib/widgets/step_editor_header.dart
//
// Shared stepper header (title + step label + progress ring) and step-tab
// bar, matching the look established in the Create Invoice flow
// (lib/screens/invoice_create_section/editor_screen.dart). Quote and
// Receipt editors both use this so all three flows share one header/theme
// shell, parameterised by accent colour, title, and step list.

import 'package:flutter/material.dart';

class StepMeta {
  final String label;
  final IconData icon;
  const StepMeta({required this.label, required this.icon});
}

class StepEditorHeader extends StatelessWidget {
  final String title;
  final int currentStep;
  final List<StepMeta> steps;
  final Color accent;
  final VoidCallback onBack;
  final ValueChanged<int> onStepTap;
  final ScrollController? stepBarController;

  const StepEditorHeader({
    super.key,
    required this.title,
    required this.currentStep,
    required this.steps,
    required this.accent,
    required this.onBack,
    required this.onStepTap,
    this.stepBarController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        _buildStepBar(context),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final stepLabel = steps[currentStep].label;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Step ${currentStep + 1} of ${steps.length} · $stepLabel',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: (currentStep + 1) / steps.length,
                      backgroundColor: const Color(0x26FFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '${((currentStep + 1) / steps.length * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBar(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      child: SingleChildScrollView(
        controller: stepBarController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: List.generate(steps.length, (i) {
            final isActive = i == currentStep;
            final isDone = i < currentStep;
            return GestureDetector(
              onTap: () => onStepTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent
                      : isDone
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? accent : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_rounded : steps[i].icon,
                      size: 14,
                      color: isActive || isDone
                          ? Colors.white
                          : const Color(0x66FFFFFF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      steps[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive || isDone
                            ? Colors.white
                            : const Color(0x66FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
