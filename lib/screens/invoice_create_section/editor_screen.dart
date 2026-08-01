// lib/screens/invoice_create_section/editor_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import 'step_customers.dart';
import 'step_templates/step_templates.dart';
import 'step_create_invoice.dart';
import 'step_customize/step_customise.dart'; // ← NEW

class EditorScreen extends StatefulWidget {
  final int initialStep;

  /// Visual layout template id chosen on InvoiceTemplateChooserScreen
  /// (see lib/screens/invoice_template_chooser_screen.dart and
  /// invoice_create_section/invoice_template_chooser_01/preview_registry.dart
  /// for the id scheme — 1 = Executive, currently the only built layout).
  /// Defaults to 1 so EditorScreen still works if pushed directly
  /// (e.g. from an old deep link) without going through the chooser first.
  ///
  /// TODO: thread this into StepCreateInvoice / invoice_pdf_service.dart
  /// once those are shared, so the chosen layout actually drives PDF
  /// rendering. For now it's stored but not yet consumed downstream.
  final int layoutTemplateId;

  const EditorScreen({
    super.key,
    this.initialStep = 0,
    this.layoutTemplateId = 1,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late int _currentStep;
  late int _layoutTemplateId;

  final ScrollController _stepBarController = ScrollController();
  late final List<GlobalKey> _stepKeys =
      List.generate(_stepMeta.length, (_) => GlobalKey());

  // ---------------------------------------------------------------------------
  // Step definitions  (Invoice → Create Invoice, + Customise)
  // ---------------------------------------------------------------------------

  static const List<_StepMeta> _stepMeta = [
    _StepMeta(label: 'Customer',       icon: Icons.people_rounded),
    _StepMeta(label: 'Template',       icon: Icons.description_rounded),
    _StepMeta(label: 'Create Invoice', icon: Icons.receipt_long_rounded), // renamed
    _StepMeta(label: 'Customise',      icon: Icons.palette_rounded),      // NEW
  ];

  // Shared state passed between steps
  dynamic _selectedCustomer;   // Customer? from invoice_models
  dynamic _selectedTemplate;   // InvoiceTemplate? from invoice_models

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _stepMeta.length - 1);
    _layoutTemplateId = widget.layoutTemplateId;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToStep(_currentStep));
  }

  void _scrollToStep(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  void _goNext() {
    if (_currentStep < _stepMeta.length - 1) {
      setState(() => _currentStep++);
      _scrollToStep(_currentStep);
    }
  }

  void _goPrev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _scrollToStep(_currentStep);
    } else {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Step content
  // ---------------------------------------------------------------------------

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return StepCustomers(
          key: const ValueKey('customers'),
          onNext: _goNext,
          onBack: _goPrev,
          selectedCustomer: _selectedCustomer,
          onCustomerChanged: (c) => setState(() => _selectedCustomer = c),
        );
      case 1:
        return StepTemplates(
          key: const ValueKey('templates'),
          onNext: _goNext,
          onBack: _goPrev,
          selectedTemplate: _selectedTemplate,
          onTemplateChanged: (t) => setState(() => _selectedTemplate = t),
        );
      case 2:
        return StepCreateInvoice(
          key: const ValueKey('create'),
          onNext: _goNext, // ← pass onNext so it can advance to Customise
          onBack: _goPrev,
          selectedCustomer: _selectedCustomer,
          selectedTemplate: _selectedTemplate,
          // layoutTemplateId: _layoutTemplateId, // ← uncomment once
          // StepCreateInvoice accepts this param and wires it through to
          // invoice_pdf_service.dart's template selection.
        );
      case 3: // ← NEW
        return StepCustomise(
          key: const ValueKey('customise'),
          onBack: _goPrev,
        );
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildStepBar(context),
          Expanded(child: _buildStepContent()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final stepLabel = _stepMeta[_currentStep].label;

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
                onTap: () => Navigator.pop(context),
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
                    const Text(
                      'Create Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of ${_stepMeta.length} · $stepLabel',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: (_currentStep + 1) / _stepMeta.length,
                      backgroundColor: const Color(0x26FFFFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2196F3)),
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / _stepMeta.length * 100).toInt()}%',
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
        controller: _stepBarController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: List.generate(_stepMeta.length, (i) {
            final isActive = i == _currentStep;
            final isDone   = i < _currentStep;
            return GestureDetector(
              onTap: () {
                setState(() => _currentStep = i);
                _scrollToStep(i);
              },
              child: AnimatedContainer(
                key: _stepKeys[i],
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2196F3)
                      : isDone
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF2196F3)
                        : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_rounded : _stepMeta[i].icon,
                      size: 14,
                      color: isActive || isDone
                          ? Colors.white
                          : const Color(0x66FFFFFF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _stepMeta[i].label,
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

  @override
  void dispose() {
    _stepBarController.dispose();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// Step metadata
// -----------------------------------------------------------------------------

class _StepMeta {
  final String   label;
  final IconData icon;
  const _StepMeta({required this.label, required this.icon});
}
