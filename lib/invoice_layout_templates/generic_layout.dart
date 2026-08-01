// generic_layout.dart
// lib/cv_layout_geometry_templates/generic_layout.dart
//
// Font-aware page splitting for templates that do not yet have their own
// dedicated layout file. Provides all the getters that templates previously
// expected on CVTemplateData (experiencePage1, needsPage2 etc.).
//
// Usage in any template:
//   late final _layout = GenericLayout(data);
// Then replace data.experiencePage1 with _layout.experiencePage1 etc.

import '../cv_template_data/cv_template_data.dart';

const double _kPageH   = 842.0;
const double _kPadVT   = 52.0;
const double _kSafeBot = 56.0;
const double _kBase    = 12.0;

// Conservative main column width assumption for bullet wrapping estimates.
// Individual templates can override by subclassing or copying this file.
const double _kMainWBase = 319.0;

class GenericLayout {
  final CVTemplateData data;
  GenericLayout(this.data);

  double get s => (data.fontSize / _kBase).clamp(0.7, 1.5);
  double f(double v) => v * s;
  double get mainW => _kMainWBase * s;

  //  Available body height page 1 
  double get page1BodyH {
    final nameH  = f(36) * 1.15 * 2;
    final titleH = f(13) * 1.4;
    const ruleBlk = 6.0 + 32.0 + 0.5 + 28.0;
    return _kPageH - _kPadVT - nameH - titleH - ruleBlk - 8 - _kSafeBot;
  }

  double get contBodyH => _kPageH - _kPadVT - f(40) - _kSafeBot;

  //  Per-block height estimators 
  double expBlockH(CVTemplateExperience e) {
    double h = f(12) * 1.2 + f(2) + f(11) * 1.2 + f(7);
    final cpl = (mainW / (f(11) * 0.55)).floor().clamp(20, 80);
    for (final b in e.bullets) {
      h += (b.length / cpl).ceil().clamp(1, 8) * f(11) * 1.5 + f(4);
    }
    return (h + f(22)) * 1.08;
  }

  double eduBlockH(CVTemplateEducation e) {
    double h = f(12) * 1.2 + f(2) + f(11) * 1.2;
    if (e.detail != null && e.detail!.isNotEmpty) {
      final cpl = (mainW / (f(11) * 0.55)).floor().clamp(20, 80);
      h += f(5) + (e.detail!.length / cpl).ceil().clamp(1, 4) * f(11) * 1.5;
    }
    return (h + f(22)) * 1.08;
  }

  double get summaryBlockH {
    if (data.summary.isEmpty) return 0;
    final cpl   = (mainW / (f(12) * 0.55)).floor().clamp(20, 80);
    final lines = (data.summary.length / cpl).ceil().clamp(1, 20);
    return ((f(9.5) + f(2) + f(10)) + lines * f(12) * 1.8 + f(28)) * 1.08;
  }

  double get sectionH => f(9.5) + f(2) + f(14);

  //  Experience splits 
  late final List<int> expSplit = _calcExpSplit();

  List<int> _calcExpSplit() {
    if (data.experience.isEmpty) return [0, 0, 0];
    double p1 = page1BodyH - summaryBlockH - sectionH;
    int c1 = 0;
    for (final e in data.experience) {
      final h = expBlockH(e);
      if (p1 >= h) { p1 -= h; c1++; } else break;
    }
    double p2 = contBodyH - sectionH;
    int c2 = 0;
    for (final e in data.experience.skip(c1)) {
      final h = expBlockH(e);
      if (p2 >= h) { p2 -= h; c2++; } else break;
    }
    return [c1, c2, (data.experience.length - c1 - c2).clamp(0, data.experience.length)];
  }

  List<CVTemplateExperience> get experiencePage1 => data.experience.take(expSplit[0]).toList();
  List<CVTemplateExperience> get experiencePage2 => data.experience.skip(expSplit[0]).take(expSplit[1]).toList();
  List<CVTemplateExperience> get experiencePage3 => data.experience.skip(expSplit[0] + expSplit[1]).toList();

  //  Education splits 
  late final List<int> eduSplit = _calcEduSplit();

  List<int> _calcEduSplit() {
    if (data.education.isEmpty) return [0, 0];
    double remaining = contBodyH;
    final expP2 = experiencePage2;
    if (expP2.isNotEmpty) {
      remaining -= sectionH;
      for (final e in expP2) { remaining -= expBlockH(e); }
      remaining -= f(20);
    }
    remaining -= sectionH;
    int c1 = 0;
    if (remaining > 0) {
      for (final e in data.education) {
        final h = eduBlockH(e);
        if (remaining >= h) { remaining -= h; c1++; } else break;
      }
    }
    return [c1, (data.education.length - c1).clamp(0, data.education.length)];
  }

  List<CVTemplateEducation> get educationPage1 => data.education.take(eduSplit[0]).toList();
  List<CVTemplateEducation> get educationPage2 => data.education.skip(eduSplit[0]).toList();

  //  Page flags 
  bool get needsPage2 {
    if (expSplit[1] > 0 || expSplit[2] > 0) return true;
    if (data.education.isNotEmpty) {
      final eduH = sectionH + data.education.fold(0.0, (s, e) => s + eduBlockH(e));
      if (summaryBlockH + sectionH +
          data.experience.fold(0.0, (s, e) => s + expBlockH(e)) + eduH > page1BodyH) return true;
    }
    return false;
  }

  bool get needsPage3 {
    if (!needsPage2) return false;
    return expSplit[2] > 0 || eduSplit[1] > 0;
  }

  bool get needsPage4 {
    if (!needsPage3) return false;
    return expSplit[2] > 0 && (eduSplit[1] > 0 || data.certifications.isNotEmpty);
  }

  int get pageCount {
    if (needsPage4) return 4;
    if (needsPage3) return 3;
    if (needsPage2) return 2;
    return 1;
  }
}