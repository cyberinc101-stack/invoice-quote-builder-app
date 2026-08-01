import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/invoice_data.dart';
import '../language_keys/lang_en_english.dart'; // fallback

class PDFGenerator {
  /// Pass the active translation map so the exported PDF is localised.
  /// Falls back to English if [t] is not supplied.
  static Future<File> generatePDF(
    CVData cvData,
    CVTemplate template, {
    Map<String, String> t = enEnglish,
  }) async {
    final pdf = pw.Document();

    switch (template) {
      case CVTemplate.modern:
        _addModernTemplate(pdf, cvData, t);
        break;
      case CVTemplate.classic:
        _addClassicTemplate(pdf, cvData, t);
        break;
      case CVTemplate.professional:
        _addProfessionalTemplate(pdf, cvData, t);
        break;
      case CVTemplate.creative:
        _addCreativeTemplate(pdf, cvData, t);
        break;
      case CVTemplate.minimal:
        _addMinimalTemplate(pdf, cvData, t);
        break;
    }

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/cv_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static PdfColor _getPdfColor(CVColor color) {
    switch (color) {
      case CVColor.blue:   return PdfColors.blue;
      case CVColor.green:  return PdfColors.green;
      case CVColor.purple: return PdfColors.purple;
      case CVColor.orange: return PdfColors.orange;
      case CVColor.red:    return PdfColors.red;
      case CVColor.teal:   return PdfColors.teal;
      case CVColor.indigo: return PdfColors.indigo;
      case CVColor.black:  return PdfColors.grey800;
    }
  }

  // ── Modern ───────────────────────────────────────────────────────────────

  static void _addModernTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: primaryColor),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(cvData.fullName,
                        style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 5),
                    pw.Text(cvData.jobTitle,
                        style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColor(1, 1, 1, 0.7))),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Contact Info
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildContactItem(t['pdf_label_email']!, cvData.email),
                    _buildContactItem(t['pdf_label_phone']!, cvData.phone),
                    if (cvData.location.isNotEmpty)
                      _buildContactItem(
                          t['pdf_label_location']!, cvData.location),
                  ],
                ),
              ),

              // Summary
              if (cvData.summary.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          t['pdf_section_summary']!, primaryColor),
                      pw.SizedBox(height: 8),
                      pw.Text(cvData.summary,
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],

              // Experience
              if (cvData.experience.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          t['pdf_section_experience']!, primaryColor),
                      pw.SizedBox(height: 8),
                      ...cvData.experience
                          .map((exp) => _buildExperience(exp)),
                    ],
                  ),
                ),
              ],

              // Education
              if (cvData.education.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          t['pdf_section_education']!, primaryColor),
                      pw.SizedBox(height: 8),
                      ...cvData.education
                          .map((edu) => _buildEducation(edu)),
                    ],
                  ),
                ),
              ],

              // Skills
              if (cvData.skills.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          t['pdf_section_skills']!, primaryColor),
                      pw.SizedBox(height: 8),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: cvData.skills.map((skill) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: primaryColor.shade(0.1),
                              borderRadius:
                                  pw.BorderRadius.circular(15),
                            ),
                            child: pw.Text(skill.name,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    color: primaryColor)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Classic ──────────────────────────────────────────────────────────────

  static void _addClassicTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Column(
                children: [
                  pw.Text(cvData.fullName,
                      style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(cvData.jobTitle,
                      style: pw.TextStyle(
                          fontSize: 16, color: primaryColor)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${cvData.email} • ${cvData.phone}'
                    '${cvData.location.isNotEmpty ? ' • ${cvData.location}' : ''}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 20),

              // Summary — uses shorter heading for Classic
              if (cvData.summary.isNotEmpty) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _buildSectionTitle(
                      t['pdf_section_summary_short']!, primaryColor),
                ),
                pw.SizedBox(height: 8),
                pw.Text(cvData.summary,
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 20),
              ],

              // Experience — uses shorter heading for Classic
              if (cvData.experience.isNotEmpty) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _buildSectionTitle(
                      t['pdf_section_experience_short']!, primaryColor),
                ),
                pw.SizedBox(height: 8),
                ...cvData.experience.map((exp) => _buildExperience(exp)),
                pw.SizedBox(height: 20),
              ],

              // Education
              if (cvData.education.isNotEmpty) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _buildSectionTitle(
                      t['pdf_section_education']!, primaryColor),
                ),
                pw.SizedBox(height: 8),
                ...cvData.education.map((edu) => _buildEducation(edu)),
                pw.SizedBox(height: 20),
              ],

              // Skills
              if (cvData.skills.isNotEmpty) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _buildSectionTitle(
                      t['pdf_section_skills']!, primaryColor),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                    cvData.skills.map((s) => s.name).join(' • '),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Professional ─────────────────────────────────────────────────────────

  static void _addProfessionalTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left sidebar
              pw.Container(
                width: 180,
                color: primaryColor,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text((t['pdf_section_contact']!).toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 10),
                    _buildSidebarItem(
                        t['pdf_label_email']!, cvData.email, PdfColors.white),
                    _buildSidebarItem(
                        t['pdf_label_phone']!, cvData.phone, PdfColors.white),
                    if (cvData.location.isNotEmpty)
                      _buildSidebarItem(t['pdf_label_location']!,
                          cvData.location, PdfColors.white),

                    if (cvData.skills.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      pw.Text((t['pdf_section_skills']!).toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 10),
                      ...cvData.skills.map((skill) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(skill.name,
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.white)),
                                pw.SizedBox(height: 3),
                                pw.Stack(
                                  children: [
                                    pw.Container(
                                      width: 140,
                                      height: 4,
                                      decoration: pw.BoxDecoration(
                                        color: PdfColor(1, 1, 1, 0.3),
                                        borderRadius:
                                            pw.BorderRadius.circular(2),
                                      ),
                                    ),
                                    pw.Container(
                                      width: 140 *
                                          (skill.proficiency / 100),
                                      height: 4,
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.white,
                                        borderRadius:
                                            pw.BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    ],

                    if (cvData.languages.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      pw.Text((t['pdf_section_languages']!).toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 10),
                      ...cvData.languages.map((lang) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(bottom: 5),
                            child: pw.Text('• $lang',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.white)),
                          )),
                    ],
                  ],
                ),
              ),

              // Right content
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(cvData.fullName.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(cvData.jobTitle,
                          style: pw.TextStyle(
                              fontSize: 16, color: primaryColor)),

                      if (cvData.summary.isNotEmpty) ...[
                        pw.SizedBox(height: 20),
                        pw.Text((t['pdf_section_profile']!).toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.Divider(color: primaryColor),
                        pw.SizedBox(height: 5),
                        pw.Text(cvData.summary,
                            style: const pw.TextStyle(fontSize: 10)),
                      ],

                      if (cvData.experience.isNotEmpty) ...[
                        pw.SizedBox(height: 20),
                        pw.Text(
                            (t['pdf_section_experience']!).toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.Divider(color: primaryColor),
                        pw.SizedBox(height: 5),
                        ...cvData.experience
                            .map((exp) => _buildExperience(exp)),
                      ],

                      if (cvData.education.isNotEmpty) ...[
                        pw.SizedBox(height: 20),
                        pw.Text(
                            (t['pdf_section_education']!).toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.Divider(color: primaryColor),
                        pw.SizedBox(height: 5),
                        ...cvData.education
                            .map((edu) => _buildEducation(edu)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Creative ─────────────────────────────────────────────────────────────

  static void _addCreativeTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                height: 100,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [primaryColor, primaryColor.shade(0.7)],
                  ),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(cvData.fullName,
                          style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 5),
                      pw.Text(cvData.jobTitle,
                          style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColor(1, 1, 1, 0.7))),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Contact boxes
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCreativeContactBox(
                        '📧', cvData.email, primaryColor),
                    _buildCreativeContactBox(
                        '📱', cvData.phone, primaryColor),
                    if (cvData.location.isNotEmpty)
                      _buildCreativeContactBox(
                          '📍', cvData.location, primaryColor),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Content
              pw.Expanded(
                child: pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (cvData.summary.isNotEmpty) ...[
                        _buildCreativeSectionTitle(
                            t['pdf_section_about_me']!, primaryColor),
                        pw.SizedBox(height: 8),
                        pw.Text(cvData.summary,
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 20),
                      ],

                      if (cvData.experience.isNotEmpty) ...[
                        _buildCreativeSectionTitle(
                            t['pdf_section_experience_short']!,
                            primaryColor),
                        pw.SizedBox(height: 8),
                        ...cvData.experience
                            .map((exp) => _buildExperience(exp)),
                        pw.SizedBox(height: 20),
                      ],

                      if (cvData.education.isNotEmpty) ...[
                        _buildCreativeSectionTitle(
                            t['pdf_section_education']!, primaryColor),
                        pw.SizedBox(height: 8),
                        ...cvData.education
                            .map((edu) => _buildEducation(edu)),
                        pw.SizedBox(height: 20),
                      ],

                      if (cvData.skills.isNotEmpty) ...[
                        _buildCreativeSectionTitle(
                            t['pdf_section_skills']!, primaryColor),
                        pw.SizedBox(height: 8),
                        pw.Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cvData.skills.map((skill) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: primaryColor, width: 2),
                                borderRadius:
                                    pw.BorderRadius.circular(20),
                              ),
                              child: pw.Text(skill.name,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      color: primaryColor)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Minimal ──────────────────────────────────────────────────────────────

  static void _addMinimalTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(cvData.fullName,
                    style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: -0.5)),
                pw.SizedBox(height: 5),
                pw.Text(cvData.jobTitle,
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 15),
                pw.Text(
                  '${cvData.email}  |  ${cvData.phone}'
                  '${cvData.location.isNotEmpty ? '  |  ${cvData.location}' : ''}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 30),

                // Summary
                if (cvData.summary.isNotEmpty) ...[
                  pw.Text(cvData.summary,
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 25),
                ],

                // Experience
                if (cvData.experience.isNotEmpty) ...[
                  pw.Text(
                      (t['pdf_section_experience']!).toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                      width: 50, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 12),
                  ...cvData.experience
                      .map((exp) => _buildMinimalExperience(exp)),
                  pw.SizedBox(height: 25),
                ],

                // Education
                if (cvData.education.isNotEmpty) ...[
                  pw.Text(
                      (t['pdf_section_education']!).toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                      width: 50, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 12),
                  ...cvData.education
                      .map((edu) => _buildMinimalEducation(edu)),
                  pw.SizedBox(height: 25),
                ],

                // Skills
                if (cvData.skills.isNotEmpty) ...[
                  pw.Text((t['pdf_section_skills']!).toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                      width: 50, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 12),
                  pw.Text(
                      cvData.skills.map((s) => s.name).join('  •  '),
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  static pw.Widget _buildContactItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: color, width: 2))),
      child: pw.Text(title.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

  static pw.Widget _buildExperience(Experience exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(exp.jobTitle,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('${exp.company} | ${exp.startDate} - ${exp.endDate}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          if (exp.responsibilities.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...exp.responsibilities.map((resp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10, top: 2),
                  child: pw.Text('• $resp',
                      style: const pw.TextStyle(fontSize: 9)),
                )),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildEducation(Education edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(edu.degree,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('${edu.institution} | ${edu.startDate} - ${edu.endDate}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          if (edu.description != null && edu.description!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(edu.description!,
                  style: const pw.TextStyle(fontSize: 9)),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSidebarItem(
      String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildCreativeContactBox(
      String icon, String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(icon, style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 4),
          pw.Text(text,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static pw.Widget _buildCreativeSectionTitle(
      String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 20, color: color),
        pw.SizedBox(width: 10),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildMinimalExperience(Experience exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp.jobTitle,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('${exp.startDate} - ${exp.endDate}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Text(exp.company,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          if (exp.responsibilities.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...exp.responsibilities.map((resp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text('• $resp',
                      style: const pw.TextStyle(fontSize: 9)),
                )),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMinimalEducation(Education edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(edu.degree,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('${edu.startDate} - ${edu.endDate}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Text(edu.institution,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
