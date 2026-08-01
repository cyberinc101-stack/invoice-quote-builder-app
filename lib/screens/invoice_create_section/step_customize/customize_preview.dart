// customize_preview.dart
// lib/screens/cv_edit_section/step_customize/customize_preview.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cv_provider.dart';
import '../../../../cv_template_data/cv_template_data.dart';
import '../../../../helpers/lang_helper.dart';
import 'customize_color_section.dart';

import '../cv_template_chooser_01/preview_registry.dart'
    show kTemplateIdArchivist, kTemplateIdDiplomat, kTemplateIdMeridian, kTemplateIdMomentum;

import '../../../../cv_templates/template_01_executive.dart';
import '../../../../cv_templates/template_02_nordic.dart';
import '../../../../cv_templates/template_03_vibrant.dart';
import '../../../../cv_templates/template_04_tech.dart';
import '../../../../cv_templates/template_05_luxury.dart';
import '../../../../cv_templates/template_06_gradient_modern.dart';
import '../../../../cv_templates/template_07_editorial.dart';
import '../../../../cv_templates/template_08_pastel_soft.dart';
import '../../../../cv_templates/template_09_brutallist.dart';
import '../../../../cv_templates/template_10_emerald.dart';
import '../../../../cv_templates/template_11_infographic.dart';
import '../../../../cv_templates/template_12_art_deco.dart';
import '../../../../cv_templates/template_13_wina.dart';
import '../../../../cv_templates/template_14_rio.dart';
import '../../../../cv_templates/template_15_summer.dart';
import '../../../../cv_templates/template_16_helene.dart';
import '../../../../cv_templates/template_17_canfield.dart';
import '../../../../cv_templates/template_18_collins.dart';
import '../../../../cv_templates/template_19_tony.dart';
import '../../../../cv_templates/template_20_fashion.dart';
import '../../../../cv_templates/template_21_archival.dart';
import '../../../../cv_templates/template_22_diplomat.dart';
import '../../../../cv_templates/template_23_meridian.dart';
import '../../../../cv_templates/template_24_momentum.dart';

const double _kNativeW         = 595.0;
const double _kNativeH         = 842.0;
const double _kPageGap         = 16.0;
const double _kParentPadH      = 20.0;
const int    _kMaxPreviewPages = 12;

// -----------------------------------------------------------------------------
// Template ID migration
//
// CVs saved under old/stale template IDs are remapped here before the switch.
// Add any retired ID ? current ID mappings as the app evolves.
// -----------------------------------------------------------------------------
const Map<int, int> _kTemplateIdMigrations = {
  25: kTemplateIdMeridian,   // old Scholar/Meridian ID ? 23
  35: kTemplateIdMomentum,   // old Vanguard/Momentum ID ? 24
  45: 20,                    // old Blueprint/Fashion ID ? 20
};

int _migrateTemplateId(int id) => _kTemplateIdMigrations[id] ?? id;

// -----------------------------------------------------------------------------

bool templateSupportsColorSelector(int templateId) {
  const noColorTemplates = {6, 7, 10};
  return !noColorTemplates.contains(templateId);
}

bool templateSupportsSmartLayout(int templateId) {
  const noSmartLayoutTemplates = {7, 9};
  final noSmartLayoutDotFive   = {
    kTemplateIdArchivist,
    kTemplateIdDiplomat,
    kTemplateIdMeridian,
    kTemplateIdMomentum,
  };
  return !noSmartLayoutTemplates.contains(templateId) &&
         !noSmartLayoutDotFive.contains(templateId);
}

Widget _buildTemplateWidget(
    int templateId, CVTemplateData data, bool smartLayout, Color accent) {
  // Remap any stale IDs from older saved CVs before switching
  templateId = _migrateTemplateId(templateId);

  switch (templateId) {
    case 1:  return Template01Executive(data: data, smartLayout: smartLayout);
    case 2:  return Template02Nordic(data: data, smartLayout: smartLayout);
    case 3:  return Template03Vibrant(data: data, smartLayout: smartLayout);
    case 4:  return Template04TechDark(data: data, smartLayout: smartLayout);
    case 5:  return Template05Luxury(data: data, smartLayout: smartLayout);
    case 6:  return Template06Gradient(data: data, smartLayout: smartLayout);
    case 7:  return Template07Editorial(data: data, smartLayout: smartLayout);
    case 8:  return Template08PastelSoft(data: data, smartLayout: smartLayout);
    case 9:  return Template09Brutalist(data: data, smartLayout: smartLayout);
    case 10: return Template10Emerald(data: data, smartLayout: smartLayout);
    case 11: return Template11Infographic(data: data, smartLayout: smartLayout);
    case 12: return Template12ArtDeco(data: data);
    case 13: return Template13Wina(data: data, smartLayout: smartLayout);
    case 14: return Template14Rio(data: data, smartLayout: smartLayout);
    case 15: return Template15Summer(data: data, smartLayout: smartLayout);
    case 16: return Template16Helene(data: data, smartLayout: smartLayout);
    case 17: return Template17Canfield(data: data, smartLayout: smartLayout);
    case 18: return Template18Collins(data: data);
    case 19: return Template19Tony(data: data, smartLayout: smartLayout);
    case 20: return Template20Fashion(data: data, smartLayout: smartLayout);
    case kTemplateIdArchivist: return Template21Archival(data: data, accent: accent);
    case kTemplateIdDiplomat:  return Template22Diplomat(data: data);
    case kTemplateIdMeridian:  return Template23Meridian(data: data);
    case kTemplateIdMomentum:  return Template24Momentum(data: data);
    default: return _UnregisteredTemplate(templateId: templateId);
  }
}

Widget _buildTemplateWidgetWithCallback(
    int templateId,
    CVTemplateData data,
    void Function(int) onPageCount,
    bool smartLayout,
    Color accent,
) {
  // Remap any stale IDs from older saved CVs before switching
  templateId = _migrateTemplateId(templateId);

  switch (templateId) {
    case 1:  return Template01Executive(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 2:  return Template02Nordic(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 3:  return Template03Vibrant(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 4:  return Template04TechDark(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 5:  return Template05Luxury(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 6:  return Template06Gradient(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 7:  return Template07Editorial(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 8:  return Template08PastelSoft(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 9:  return Template09Brutalist(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 10: return Template10Emerald(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 11: return Template11Infographic(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 12: return Template12ArtDeco(data: data, onPageCount: onPageCount);
    case 13: return Template13Wina(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 14: return Template14Rio(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 15: return Template15Summer(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 16: return Template16Helene(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 17: return Template17Canfield(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 18: return Template18Collins(data: data, onPageCount: onPageCount);
    case 19: return Template19Tony(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case 20: return Template20Fashion(data: data, onPageCount: onPageCount, smartLayout: smartLayout);
    case kTemplateIdArchivist: return Template21Archival(data: data, accent: accent, onPageCount: onPageCount);
    case kTemplateIdDiplomat:  return Template22Diplomat(data: data, onPageCount: onPageCount);
    case kTemplateIdMeridian:  return Template23Meridian(data: data, onPageCount: onPageCount);
    case kTemplateIdMomentum:  return Template24Momentum(data: data, onPageCount: onPageCount);
    default: return _UnregisteredTemplate(templateId: templateId);
  }
}

// -----------------------------------------------------------------------------
// CustomizePreview
// -----------------------------------------------------------------------------
class CustomizePreview extends StatefulWidget {
  const CustomizePreview({super.key});
  @override
  State<CustomizePreview> createState() => _CustomizePreviewState();
}

class _CustomizePreviewState extends State<CustomizePreview> {
  int _pageCount = 1;

  @override
  Widget build(BuildContext context) {
    final t = getLang(context);

    return Consumer<CVProvider>(
      builder: (context, provider, _) {
        final cvData      = provider.cvData;
        final templateId  = provider.templateId;
        final smartLayout = provider.smartLayout;
        final accent      = cvColorToFlutter(cvData.colorScheme);
        final data        = CVTemplateData.fromCVData(cvData);

        final screenW = MediaQuery.of(context).size.width;
        final availW  = screenW - (_kParentPadH * 2);
        final scale   = availW / _kNativeW;
        final pageH   = _kNativeH * scale;

        final totalPages = _pageCount.clamp(1, _kMaxPreviewPages);

        final sharedWidget = _buildTemplateWidgetWithCallback(
          templateId,
          data,
          (count) {
            if (count != _pageCount) setState(() => _pageCount = count);
          },
          smartLayout,
          accent,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Row(children: [
                Container(width: 7, height: 7,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text(t['preview_live_label'] ?? 'Live Preview',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                const Spacer(),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.article_outlined, size: 13, color: Color(0xFF888888)),
                  const SizedBox(width: 4),
                  Text(
                    totalPages == 1
                        ? (t['preview_page_count_singular'] ?? '1 page')
                        : (t['preview_page_count_plural'] ?? '{n} pages')
                            .replaceAll('{n}', '$totalPages'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Color(0xFF666666))),
                ]),
              ]),
            ),
            for (int p = 1; p <= totalPages; p++) ...[
              if (p > 1) _PageDivider(page: p, total: totalPages, accent: accent, t: t),
              _ScaledPageCard(
                  availW: availW, pageH: pageH, scale: scale, page: p, child: sharedWidget),
            ],
            const SizedBox(height: 8),
            Center(
              child: Text(t['preview_live_hint'] ?? 'Live preview — changes appear instantly.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400],
                      fontStyle: FontStyle.italic)),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Scaled page card
// -----------------------------------------------------------------------------
class _ScaledPageCard extends StatelessWidget {
  final double availW, pageH, scale;
  final int    page;
  final Widget child;
  const _ScaledPageCard({
      required this.availW, required this.pageH, required this.scale,
      required this.page, required this.child});

  @override
  Widget build(BuildContext context) {
    final nativeOffset = (page - 1) * (_kNativeH + _kPageGap);
    return Container(
      width: availW, height: pageH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.hardEdge,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _kNativeW, maxWidth: _kNativeW,
          minHeight: 0, maxHeight: double.infinity,
          child: Transform.scale(scale: scale, alignment: Alignment.topLeft,
            child: Transform.translate(offset: Offset(0, -nativeOffset), child: child)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Page divider
// -----------------------------------------------------------------------------
class _PageDivider extends StatelessWidget {
  final int page, total;
  final Color accent;
  final Map<String, String> t;
  const _PageDivider({
    required this.page,
    required this.total,
    required this.accent,
    required this.t,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0))),
        child: Text(
          (t['preview_page_of'] ?? 'Page {page} of {total}')
              .replaceAll('{page}',  '$page')
              .replaceAll('{total}', '$total'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Color(0xFF888888))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
    ]),
  );
}

// -----------------------------------------------------------------------------
// Unregistered template placeholder
// -----------------------------------------------------------------------------
class _UnregisteredTemplate extends StatelessWidget {
  final int templateId;
  const _UnregisteredTemplate({required this.templateId});

  @override
  Widget build(BuildContext context) {
    final t = getLang(context);
    return SizedBox(
      width: _kNativeW,
      child: Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB74D), width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.build_circle_outlined, size: 48, color: Color(0xFFF57C00)),
            const SizedBox(height: 16),
            Text('$templateId',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(t['preview_template_unregistered'] ?? 'Template not yet registered.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF795548))),
          ]),
        ),
      )),
    );
  }
}