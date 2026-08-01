import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_data.dart';
import '../language_keys/lang_en_english.dart'; // fallback

class PDFService {
  /// Pass the active translation map so the exported PDF is localised.
  /// Falls back to English if [t] is not supplied.
  static Future<Uint8List> generatePDF(
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

    return pdf.save();
  }

  static PdfColor _getPdfColor(CVColor color) {
    switch (color) {
      case CVColor.blue:   return PdfColors.blue700;
      case CVColor.green:  return PdfColors.green700;
      case CVColor.purple: return PdfColors.purple700;
      case CVColor.orange: return PdfColors.orange700;
      case CVColor.red:    return PdfColors.red700;
      case CVColor.teal:   return PdfColors.teal700;
      case CVColor.indigo: return PdfColors.indigo700;
    }
  }

  // ── Modern ───────────────────────────────────────────────────────────────

  static void _addModernTemplate(
      pw.Document pdf, CVData cvData, Map<String, String> t) {
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(cvData.fullName,
                        style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    if (cvData.jobTitle.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(cvData.jobTitle,
                          style: const pw.TextStyle(
                              fontSize: 18, color: PdfColors.white)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Contact Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (cvData.email.isNotEmpty)
                    _buildContactItem(t['pdf_label_email']!, cvData.email),
                  if (cvData.phone.isNotEmpty)
                    _buildContactItem(t['pdf_label_phone']!, cvData.phone),
                  if (cvData.location.isNotEmpty)
                    _buildContactItem(
                        t['pdf_label_location']!, cvData.location),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              if (cvData.summary.isNotEmpty) ...[
                _buildSection(t['pdf_section_summary']!, primaryColor),
                pw.Text(cvData.summary, textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 20),
              ],

              // Experience
              if (cvData.experience.isNotEmpty) ...[
                _buildSection(t['pdf_section_experience']!, primaryColor),
                ...cvData.experience.map((exp) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.jobTitle,
                                  style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('${exp.startDate} - ${exp.endDate}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: pw.TextStyle(
                                  fontSize: 12, color: primaryColor)),
                          if (exp.responsibilities.isNotEmpty) ...[
                            pw.SizedBox(height: 5),
                            ...exp.responsibilities.map((resp) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 10, top: 3),
                                  child: pw.Text('• $resp',
                                      style:
                                          const pw.TextStyle(fontSize: 10)),
                                )),
                          ],
                        ],
                      ),
                    )),
                pw.SizedBox(height: 20),
              ],

              // Education
              if (cvData.education.isNotEmpty) ...[
                _buildSection(t['pdf_section_education']!, primaryColor),
                ...cvData.education.map((edu) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(edu.degree,
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('${edu.startDate} - ${edu.endDate}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.Text(edu.institution,
                              style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 20),
              ],

              // Skills
              if (cvData.skills.isNotEmpty) ...[
                _buildSection(t['pdf_section_skills']!, primaryColor),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cvData.skills
                      .map((skill) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: primaryColor.flatten(),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(15)),
                            ),
                            child: pw.Text(skill.name,
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.white)),
                          ))
                      .toList(),
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
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(cvData.fullName,
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  if (cvData.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(cvData.jobTitle,
                        style: pw.TextStyle(
                            fontSize: 14, color: primaryColor)),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Container(
                      width: double.infinity,
                      height: 2,
                      color: primaryColor),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (cvData.email.isNotEmpty)
                        pw.Text('${cvData.email}  ',
                            style: const pw.TextStyle(fontSize: 10)),
                      if (cvData.phone.isNotEmpty)
                        pw.Text('${cvData.phone}  ',
                            style: const pw.TextStyle(fontSize: 10)),
                      if (cvData.location.isNotEmpty)
                        pw.Text(cvData.location,
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              if (cvData.summary.isNotEmpty) ...[
                _buildClassicSection(
                    (t['pdf_section_summary']!).toUpperCase(), primaryColor),
                pw.Text(cvData.summary,
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 20),
              ],

              // Experience
              if (cvData.experience.isNotEmpty) ...[
                _buildClassicSection(
                    (t['pdf_section_experience']!).toUpperCase(), primaryColor),
                ...cvData.experience.map((exp) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(exp.jobTitle,
                              style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              '${exp.company} | ${exp.startDate} - ${exp.endDate}',
                              style: const pw.TextStyle(fontSize: 10)),
                          if (exp.responsibilities.isNotEmpty) ...[
                            pw.SizedBox(height: 5),
                            ...exp.responsibilities.map((resp) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 15, top: 2),
                                  child: pw.Text('• $resp',
                                      style:
                                          const pw.TextStyle(fontSize: 10)),
                                )),
                          ],
                        ],
                      ),
                    )),
                pw.SizedBox(height: 20),
              ],

              // Education
              if (cvData.education.isNotEmpty) ...[
                _buildClassicSection(
                    (t['pdf_section_education']!).toUpperCase(), primaryColor),
                ...cvData.education.map((edu) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu.degree,
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              '${edu.institution} | ${edu.startDate} - ${edu.endDate}',
                              style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 20),
              ],

              // Skills
              if (cvData.skills.isNotEmpty) ...[
                _buildClassicSection(
                    (t['pdf_section_skills']!).toUpperCase(), primaryColor),
                pw.Text(cvData.skills.map((s) => s.name).join(' • '),
                    style: const pw.TextStyle(fontSize: 11)),
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
        margin: pw.EdgeInsets.zero,
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
                    pw.SizedBox(height: 20),
                    pw.Text(cvData.fullName,
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    if (cvData.jobTitle.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(cvData.jobTitle,
                          style: const pw.TextStyle(
                              fontSize: 12, color: PdfColors.white)),
                    ],
                    pw.SizedBox(height: 30),

                    // Contact
                    _buildSidebarSection(
                        (t['pdf_section_contact']!).toUpperCase(),
                        PdfColors.white),
                    if (cvData.email.isNotEmpty)
                      _buildSidebarItem(
                          t['pdf_label_email']!, cvData.email, PdfColors.white),
                    if (cvData.phone.isNotEmpty)
                      _buildSidebarItem(
                          t['pdf_label_phone']!, cvData.phone, PdfColors.white),
                    if (cvData.location.isNotEmpty)
                      _buildSidebarItem(t['pdf_label_location']!,
                          cvData.location, PdfColors.white),
                    pw.SizedBox(height: 20),

                    // Skills
                    if (cvData.skills.isNotEmpty) ...[
                      _buildSidebarSection(
                          (t['pdf_section_skills']!).toUpperCase(),
                          PdfColors.white),
                      ...cvData.skills.map((skill) => pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(skill.name,
                                    style: const pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.white)),
                                pw.SizedBox(height: 3),
                                pw.Container(
                                  width: 140,
                                  height: 6,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white.flatten(),
                                    borderRadius: const pw.BorderRadius.all(
                                        pw.Radius.circular(3)),
                                  ),
                                  child: pw.FractionallySizedBox(
                                    alignment: pw.Alignment.centerLeft,
                                    widthFactor: skill.proficiency / 100,
                                    child: pw.Container(
                                      decoration: const pw.BoxDecoration(
                                        color: PdfColors.white,
                                        borderRadius: pw.BorderRadius.all(
                                            pw.Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),

              // Right content
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Summary
                      if (cvData.summary.isNotEmpty) ...[
                        _buildProfessionalSection(
                            (t['pdf_section_profile']!).toUpperCase(),
                            primaryColor),
                        pw.Text(cvData.summary,
                            textAlign: pw.TextAlign.justify,
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 20),
                      ],

                      // Experience
                      if (cvData.experience.isNotEmpty) ...[
                        _buildProfessionalSection(
                            (t['pdf_section_experience']!).toUpperCase(),
                            primaryColor),
                        ...cvData.experience.map((exp) => pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 12),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(exp.jobTitle,
                                      style: pw.TextStyle(
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                      '${exp.company} | ${exp.startDate} - ${exp.endDate}',
                                      style:
                                          const pw.TextStyle(fontSize: 9)),
                                  if (exp.responsibilities.isNotEmpty) ...[
                                    pw.SizedBox(height: 4),
                                    ...exp.responsibilities
                                        .map((resp) => pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.only(
                                                      left: 10, top: 2),
                                              child: pw.Text('• $resp',
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                            )),
                                  ],
                                ],
                              ),
                            )),
                        pw.SizedBox(height: 20),
                      ],

                      // Education
                      if (cvData.education.isNotEmpty) ...[
                        _buildProfessionalSection(
                            (t['pdf_section_education']!).toUpperCase(),
                            primaryColor),
                        ...cvData.education.map((edu) => pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(edu.degree,
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                      '${edu.institution} | ${edu.startDate} - ${edu.endDate}',
                                      style:
                                          const pw.TextStyle(fontSize: 9)),
                                ],
                              ),
                            )),
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
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                        color: primaryColor, shape: pw.BoxShape.circle),
                    child: pw.Center(
                      child: pw.Text(
                        cvData.fullName.isNotEmpty
                            ? cvData.fullName[0].toUpperCase()
                            : '',
                        style: pw.TextStyle(
                            fontSize: 40,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(cvData.fullName,
                            style: pw.TextStyle(
                                fontSize: 26,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        if (cvData.jobTitle.isNotEmpty)
                          pw.Text(cvData.jobTitle,
                              style: const pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          [cvData.email, cvData.phone, cvData.location]
                              .where((s) => s.isNotEmpty)
                              .join(' | '),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // Summary
              if (cvData.summary.isNotEmpty) ...[
                _buildCreativeSection(t['pdf_section_about_me']!, primaryColor),
                pw.Text(cvData.summary,
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 20),
              ],

              // Experience
              if (cvData.experience.isNotEmpty) ...[
                _buildCreativeSection(
                    t['pdf_section_experience_short']!, primaryColor),
                ...cvData.experience.map((exp) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                            left: pw.BorderSide(
                                color: primaryColor, width: 3)),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.jobTitle,
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('${exp.startDate} - ${exp.endDate}',
                                  style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: const pw.TextStyle(fontSize: 10)),
                          if (exp.responsibilities.isNotEmpty) ...[
                            pw.SizedBox(height: 5),
                            ...exp.responsibilities.map((resp) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 10, top: 2),
                                  child: pw.Text('• $resp',
                                      style:
                                          const pw.TextStyle(fontSize: 9)),
                                )),
                          ],
                        ],
                      ),
                    )),
                pw.SizedBox(height: 20),
              ],

              // Skills & Education row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (cvData.education.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildCreativeSection(
                              t['pdf_section_education']!, primaryColor),
                          ...cvData.education.map((edu) => pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 8),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(edu.degree,
                                        style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                pw.FontWeight.bold)),
                                    pw.Text(edu.institution,
                                        style:
                                            const pw.TextStyle(fontSize: 9)),
                                    pw.Text(
                                        '${edu.startDate} - ${edu.endDate}',
                                        style: const pw.TextStyle(fontSize: 8)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  pw.SizedBox(width: 20),
                  if (cvData.skills.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildCreativeSection(
                              t['pdf_section_skills']!, primaryColor),
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cvData.skills
                                .map((skill) => pw.Container(
                                      padding:
                                          const pw.EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                      decoration: pw.BoxDecoration(
                                        color: primaryColor,
                                        borderRadius:
                                            const pw.BorderRadius.all(
                                                pw.Radius.circular(12)),
                                      ),
                                      child: pw.Text(skill.name,
                                          style: const pw.TextStyle(
                                              fontSize: 9,
                                              color: PdfColors.white)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                ],
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
    final primaryColor = _getPdfColor(cvData.colorScheme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(cvData.fullName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2)),
              if (cvData.jobTitle.isNotEmpty)
                pw.Text(cvData.jobTitle,
                    style:
                        pw.TextStyle(fontSize: 12, color: primaryColor)),
              pw.SizedBox(height: 5),
              pw.Container(width: 50, height: 2, color: primaryColor),
              pw.SizedBox(height: 15),
              pw.Text(
                [cvData.email, cvData.phone, cvData.location]
                    .where((s) => s.isNotEmpty)
                    .join('  •  '),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 25),

              // Summary
              if (cvData.summary.isNotEmpty) ...[
                pw.Text(cvData.summary,
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 25),
              ],

              // Experience
              if (cvData.experience.isNotEmpty) ...[
                pw.Text((t['pdf_section_experience']!).toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1)),
                pw.SizedBox(height: 2),
                pw.Container(width: 30, height: 1, color: primaryColor),
                pw.SizedBox(height: 10),
                ...cvData.experience.map((exp) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.jobTitle,
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('${exp.startDate} - ${exp.endDate}',
                                  style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: const pw.TextStyle(fontSize: 10)),
                          if (exp.responsibilities.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            ...exp.responsibilities.map((resp) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 10, top: 2),
                                  child: pw.Text('• $resp',
                                      style:
                                          const pw.TextStyle(fontSize: 9)),
                                )),
                          ],
                        ],
                      ),
                    )),
                pw.SizedBox(height: 15),
              ],

              // Education
              if (cvData.education.isNotEmpty) ...[
                pw.Text((t['pdf_section_education']!).toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1)),
                pw.SizedBox(height: 2),
                pw.Container(width: 30, height: 1, color: primaryColor),
                pw.SizedBox(height: 10),
                ...cvData.education.map((edu) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(edu.degree,
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(edu.institution,
                                    style: const pw.TextStyle(fontSize: 9)),
                              ],
                            ),
                          ),
                          pw.Text('${edu.startDate} - ${edu.endDate}',
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 15),
              ],

              // Skills
              if (cvData.skills.isNotEmpty) ...[
                pw.Text((t['pdf_section_skills']!).toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1)),
                pw.SizedBox(height: 2),
                pw.Container(width: 30, height: 1, color: primaryColor),
                pw.SizedBox(height: 10),
                pw.Text(cvData.skills.map((s) => s.name).join('  •  '),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  static pw.Widget _buildSection(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.Container(
              width: 50,
              height: 3,
              margin: const pw.EdgeInsets.only(top: 5),
              color: color),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  static pw.Widget _buildClassicSection(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: color, width: 2))),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

  static pw.Widget _buildProfessionalSection(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 20, color: color),
          pw.SizedBox(width: 8),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildCreativeSection(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

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

  static pw.Widget _buildSidebarSection(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

  static pw.Widget _buildSidebarItem(
      String label, String value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }
}

