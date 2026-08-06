// lib/widgets/step_editor_header.dart
//
// Shared stepper header (title + step label + progress ring) and step-tab
// bar, matching the look established in the Create Invoice flow
// (lib/screens/invoice_create_section/editor_screen.dart). Quote and
// Receipt editors both use this so all three flows share one header/theme
// shell, parameterised by accent colour, title, and step list.
//
// FIX (this pass): the step-tab bar didn't auto-scroll to keep the active
// step visible, unlike the Create Invoice flow (which does this manually
// in editor_screen.dart via a ScrollController + a GlobalKey per tab and
// Scrollable.ensureVisible() on every step change). Quote and Receipt both
// build this same header on every step change but had no equivalent
// logic, so once you moved a few steps in, the active step's tab (and
// eventually the tab bar itself scrolled past the visible steps) could sit
// off-screen with no automatic scroll to bring it back into view.
//
// This widget is now a StatefulWidget that owns its own ScrollController
// and a GlobalKey per step tab, and calls Scrollable.ensureVisible() on
// the active tab's key whenever currentStep changes (including on first
// build). This fixes Quote and Receipt automatically since both already
// pass `currentStep` into this widget on every rebuild — no changes needed
// in quote_editor_screen.dart or create_receipt_screen.dart.
//
// The external `stepBarController` param is kept for backwards
// compatibility (nothing currently passes one in) but is no longer the
// primary controller — if a caller does supply one, it's used instead of
// the internally-created controller so external code can still reach in.

import 'package:flutter/material.dart';

class StepMeta {
  final String label;
  final IconData icon;
  const StepMeta({required this.label, required this.icon});
}

class StepEditorHeader extends StatefulWidget {
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
  State<StepEditorHeader> createState() => _StepEditorHeaderState();
}

class _StepEditorHeaderState extends State<StepEditorHeader> {
  late final ScrollController _internalController;
  late List<GlobalKey> _stepKeys;

  ScrollController get _controller =>
      widget.stepBarController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
    _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToStep(widget.currentStep));
  }

  @override
  void didUpdateWidget(covariant StepEditorHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Steps list length changed (shouldn't normally happen, but guard
    // against a stale key list if it ever does).
    if (oldWidget.steps.length != widget.steps.length) {
      _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    }
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollToStep(widget.currentStep);
    }
  }

  void _scrollToStep(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < 0 || index >= _stepKeys.length) return;
      final ctx = _stepKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

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
    final stepLabel = widget.steps[widget.currentStep].label;

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
                onTap: widget.onBack,
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
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Step ${widget.currentStep + 1} of ${widget.steps.length} · $stepLabel',
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
                      value: (widget.currentStep + 1) / widget.steps.length,
                      backgroundColor: const Color(0x26FFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '${((widget.currentStep + 1) / widget.steps.length * 100).toInt()}%',
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
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: List.generate(widget.steps.length, (i) {
            final isActive = i == widget.currentStep;
            final isDone = i < widget.currentStep;
            return GestureDetector(
              onTap: () => widget.onStepTap(i),
              child: AnimatedContainer(
                key: _stepKeys[i],
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.accent
                      : isDone
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? widget.accent : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_rounded : widget.steps[i].icon,
                      size: 14,
                      color: isActive || isDone
                          ? Colors.white
                          : const Color(0x66FFFFFF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.steps[i].label,
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