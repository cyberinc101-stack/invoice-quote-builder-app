// lib/screens/invoice_create_section/step_customize/step_customise.dart
//
// TEMPLATE PASS (this update): _InvoicePreviewCard no longer hardcodes
// ExecutiveInvoicePreview — it now dispatches on data.layoutTemplateId via
// buildInvoicePreview() (preview_registry.dart), the same function the
// template chooser grid and its full-preview modal already use. This is
// what actually makes "the template you picked" and "the invoice you're
// customising" match — previously this live preview (and the full
// preview screen, and the PDF-preview mockup) all rendered as Executive
// regardless of what was picked in InvoiceTemplateChooserScreen. Only
// Executive is paginated (via A4Paginator/onPageCount) today, so the page
// counter badge only updates for that template; every other design
// renders as a single natural-height page.
//
// LOGO SIZER PASS (this update): added a new "Business Logo" section
// using SharedLogoPicker (same widget step_templates.dart uses for the
// saved BusinessInfo template's logo) so the actual invoice's logo can be
// repositioned/zoomed/reshaped right here, without leaving this step.
// Wired to InvoiceProvider.updateBusinessLogo(). NOTE: the underlying
// template layout files (executive_page_stationary_layout.dart etc.)
// don't yet read businessLogoOffsetDx/Dy/Scale/Shape when painting the
// logo — this control saves the values, but they won't visually move/
// zoom the logo in the preview until those layout files are updated to
// use them.
//
// FIX (earlier pass): "Preview & Download" at the bottom of this step was a
// TODO -- tapping it did nothing. It now pushes InvoiceFullPreviewScreen,
// handing it the same InvoiceProvider instance via
// ChangeNotifierProvider.value so the preview screen sees the exact invoice
// data/customisation state built up across the previous steps. Download and
// Share now live on that full preview screen (via
// invoice_preview_bottom_bar.dart) rather than here or on step_create_invoice.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../widgets/shared_logo_picker.dart';
import 'invoice_full_preview_screen.dart';
import '../../../invoice_layout_templates/01_executive_cv_layout/executive_cv_logic_data.dart';
import '../../../invoice_layout_templates/01_executive_cv_layout/executive_page_stationary_layout.dart'
    show kPageW, invoiceAccent;
import '../../../invoice_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_template_previews/preview_registry.dart' show buildInvoicePreview;

// =============================================================================
// Public entry point
// =============================================================================

class StepCustomise extends StatefulWidget {
  final VoidCallback onBack;
  const StepCustomise({super.key, required this.onBack});

  @override
  State<StepCustomise> createState() => _StepCustomiseState();
}

class _StepCustomiseState extends State<StepCustomise> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() => _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  void _openFullPreview() {
    final provider = context.read<InvoiceProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const InvoiceFullPreviewScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Text(
                  'Customise',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalise your invoice design',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Live invoice preview ----
                const _InvoicePreviewCard(),
                const SizedBox(height: 24),

                // ---- Business logo sizer ----
                const _LogoSection(),
                const SizedBox(height: 16),

                // ---- Business logo size ----
                const _LogoSizeSection(),
                const SizedBox(height: 16),

                // ---- Accent colour ----
                const _ColourSection(),
                const SizedBox(height: 16),

                // ---- Font family ----
                const _FontSection(),
                const SizedBox(height: 16),

                // ---- Text size ----
                const _SizeSection(),
                const SizedBox(height: 20),

                // ---- Back to top ----
                GestureDetector(
                  onTap: _scrollToTop,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1B2A)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF2196F3), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Back to Top',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const _DoneCard(),
              ],
            ),
          ),
        ),

        _BottomBar(onBack: widget.onBack, onPreview: _openFullPreview),
      ],
    );
  }
}

// =============================================================================
// Inline invoice preview -- renders whichever design template.layoutTemplateId
// points to, scaled to width
// =============================================================================

class _InvoicePreviewCard extends StatefulWidget {
  const _InvoicePreviewCard();

  @override
  State<_InvoicePreviewCard> createState() => _InvoicePreviewCardState();
}

class _InvoicePreviewCardState extends State<_InvoicePreviewCard> {
  int _pageCount = 1;

  void _setPageCount(int count) {
    if (count == _pageCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pageCount = count);
    });
  }

  // Dispatches on data.layoutTemplateId — Executive (id 1) is the only
  // paginated design today (via A4Paginator/onPageCount), so it's built
  // directly to keep that callback; every other template renders as a
  // single natural-height page via buildInvoicePreview(), falling back to
  // Executive if the id is unrecognized.
  Widget _buildPreviewWidget(InvoiceData data) {
    if (data.layoutTemplateId == 1) {
      return ExecutiveInvoicePreview(data: data, onPageCount: _setPageCount);
    }
    _setPageCount(1);
    return buildInvoicePreview(data.layoutTemplateId, data) ??
        ExecutiveInvoicePreview(data: data, onPageCount: _setPageCount);
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final data        = provider.invoiceData;
    final accent      = invoiceAccent(data);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text('Live Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.article_outlined, size: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 4),
              Text(_pageCount == 1 ? '1 page' : '$_pageCount pages',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ]),
          ]),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ScaledPageStack(
                  targetWidth: constraints.maxWidth,
                  nativePageWidth: kPageW,
                  child: _buildPreviewWidget(data),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Live preview - changes appear instantly.',
              style: TextStyle(fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }
}

// =============================================================================
// Business logo section — reposition/zoom/shape via SharedLogoPicker
// =============================================================================

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final data     = provider.invoiceData;
    final accent   = _colorForScheme(data.colorScheme);

    return _SectionCard(
      icon: Icons.image_rounded,
      title: 'Business Logo',
      child: SharedLogoPicker(
        logoPath: data.businessLogoPath,
        logoOffset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
        logoScale: data.businessLogoScale,
        logoShape: logoShapeFromString(data.businessLogoShape),
        accent: accent,
        onChanged: (path, offset, scale, shape) {
          provider.updateBusinessLogo(
            path: path,
            offset: offset,
            scale: scale,
            shape: shape.storageName,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Logo size section
// =============================================================================

class _LogoSizeSection extends StatelessWidget {
  const _LogoSizeSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final data        = provider.invoiceData;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _colorForScheme(data.colorScheme);
    final hasLogo = data.businessLogoPath != null && data.businessLogoPath!.isNotEmpty;

    return Opacity(
      opacity: hasLogo ? 1.0 : 0.4,
      child: _SectionCard(
        icon: Icons.photo_size_select_large_rounded,
        title: 'Logo Size',
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor:         accent,
                      overlayColor:       accent.withValues(alpha: 0.15),
                      trackHeight:        4,
                    ),
                    child: Slider(
                      value: data.businessLogoDisplaySize,
                      min: 24,
                      max: 60,
                      divisions: 9,
                      onChanged: hasLogo ? (v) => provider.updateBusinessLogoSize(v) : null,
                    ),
                  ),
                ),
                Icon(Icons.image_outlined, size: 24,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
            Text(
              hasLogo ? '${data.businessLogoDisplaySize.toInt()}px' : 'Add a logo to enable',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: hasLogo ? accent : colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Colour section
// =============================================================================

const _kPresetColors = [
  ('Ocean Blue',  InvoiceColor.blue),
  ('Slate',       InvoiceColor.black),
  ('Emerald',     InvoiceColor.green),
  ('Crimson',     InvoiceColor.red),
  ('Violet',      InvoiceColor.purple),
  ('Amber',       InvoiceColor.orange),
  ('Teal',        InvoiceColor.teal),
  ('Indigo',      InvoiceColor.indigo),
];

// Maps each InvoiceColor to its display Color for the swatch tiles
Color _colorForScheme(InvoiceColor scheme) {
  const map = {
    InvoiceColor.blue:   Color(0xFF1565C0),
    InvoiceColor.green:  Color(0xFF2E7D32),
    InvoiceColor.purple: Color(0xFF6A1B9A),
    InvoiceColor.orange: Color(0xFFE65100),
    InvoiceColor.red:    Color(0xFFC62828),
    InvoiceColor.teal:   Color(0xFF00695C),
    InvoiceColor.black:  Color(0xFF212121),
    InvoiceColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF1565C0);
}

class _ColourSection extends StatelessWidget {
  const _ColourSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.colorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.palette_rounded,
      title: 'Accent Colour',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kPresetColors.map((c) {
              final isActive = c.$2 == selected;
              final color    = _colorForScheme(c.$2);
              return GestureDetector(
                onTap: () => provider.updateColorScheme(c.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:  isActive ? 52 : 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: isActive
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                    boxShadow: isActive
                        ? [BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: isActive
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Selected: ${_kPresetColors.firstWhere(
              (c) => c.$2 == selected,
              orElse: () => ('Custom', selected),
            ).$1}',
            style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Font section
// =============================================================================

const _kFonts = [
  'Default',
  'Roboto',
  'Lato',
  'Montserrat',
  'Open Sans',
  'Playfair Display',
  'Source Sans Pro',
];

class _FontSection extends StatelessWidget {
  const _FontSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.fontFamily;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = _colorForScheme(provider.invoiceData.colorScheme);

    return _SectionCard(
      icon: Icons.text_fields_rounded,
      title: 'Font Family',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kFonts.map((font) {
          final isActive = font == selected;
          return GestureDetector(
            onTap: () => provider.updateFontFamily(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? accent
                    : isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? accent
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                font,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Size section
// =============================================================================

class _SizeSection extends StatelessWidget {
  const _SizeSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final size        = provider.fontSize;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _colorForScheme(provider.invoiceData.colorScheme);

    return _SectionCard(
      icon: Icons.format_size_rounded,
      title: 'Text Size',
      child: Column(
        children: [
          Row(
            children: [
              Text('A',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:   accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor:         accent,
                    overlayColor:       accent.withValues(alpha: 0.15),
                    trackHeight:        4,
                  ),
                  child: Slider(
                    value: size,
                    min: 10,
                    max: 16,
                    divisions: 6,
                    onChanged: (v) => provider.updateFontSize(v),
                  ),
                ),
              ),
              Text('A',
                  style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          Text(
            '${size.toInt()}pt',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: accent),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable section card
// =============================================================================

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// Done card
// =============================================================================

class _DoneCard extends StatelessWidget {
  const _DoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your invoice is ready!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Preview and download below.',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom bar
// =============================================================================

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPreview;
  const _BottomBar({required this.onBack, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.55), size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Preview & Download
          Expanded(
            child: GestureDetector(
              onTap: onPreview,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x504CAF50),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.preview_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Preview & Download',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
