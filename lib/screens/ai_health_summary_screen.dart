import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/symptom_model.dart';
import '../symptom_analyzer.dart';

class AiHealthSummaryScreen extends StatefulWidget {
  const AiHealthSummaryScreen({super.key});

  @override
  State<AiHealthSummaryScreen> createState() => _AiHealthSummaryScreenState();
}

class _AiHealthSummaryScreenState extends State<AiHealthSummaryScreen> {
  static const String _reportIdKey = 'healthSummary.reportId';

  late final Future<_ProfileSnapshot> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileSnapshot> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    String? reportId = prefs.getString(_reportIdKey);
    if (reportId == null || reportId.trim().isEmpty) {
      final n = 1000 + Random().nextInt(9000);
      reportId = 'MM-$n';
      await prefs.setString(_reportIdKey, reportId);
    }

    final age = (prefs.getString('profile.age') ?? '').trim();
    final genderRaw = (prefs.getString('profile.gender') ?? '').trim();
    final conditions = prefs.getStringList('profile.conditions') ?? const <String>[];

    return _ProfileSnapshot(
      reportId: reportId,
      reportDateLabel: DateFormat('MMM d, yyyy').format(DateTime.now()),
      ageLabel: age.isEmpty ? '--' : '$age Years',
      genderLabel: _prettyGender(genderRaw),
      medicalHistoryLabel: _prettyConditions(conditions),
    );
  }

  static String _prettyGender(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return '--';
    if (v == 'male') return 'Male';
    if (v == 'female') return 'Female';
    return '${v[0].toUpperCase()}${v.substring(1)}';
  }

  static String _prettyConditions(List<String> conditions) {
    final cleaned = conditions
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
        .toList(growable: false);
    if (cleaned.isEmpty) return 'None reported';
    return cleaned.join(', ');
  }

  AnalysisResult? _latestAnalysis(SymptomModel model) {
    for (var i = model.messages.length - 1; i >= 0; i--) {
      final m = model.messages[i];
      if (!m.isUser && m.result != null) return m.result;
    }
    return null;
  }

  List<String> _complaintsFromChat(SymptomModel model) {
    final seen = <String>{};
    final out = <String>[];

    for (var i = model.messages.length - 1; i >= 0; i--) {
      final m = model.messages[i];
      if (!m.isUser) continue;
      final t = m.text.trim();
      if (t.length < 5) continue;
      if (t.toLowerCase().startsWith('hello')) continue;

      final normalized = t.replaceAll(RegExp(r'\s+'), ' ');
      if (seen.add(normalized.toLowerCase())) {
        out.add(normalized);
      }
      if (out.length >= 3) break;
    }

    return out.reversed.toList(growable: false);
  }

  _Feeling _feelingFromAnalysis(AnalysisResult? res) {
    if (res == null) {
      return const _Feeling(label: 'Not enough data yet', color: Color(0xFF64748B), value: 0.0);
    }
    switch (res.urgency) {
      case Urgency.low:
        return const _Feeling(label: 'Mild discomfort', color: Color(0xFF16A34A), value: 0.33);
      case Urgency.medium:
        return const _Feeling(label: 'Moderate discomfort', color: Color(0xFFF97316), value: 0.66);
      case Urgency.high:
        return const _Feeling(label: 'High concern', color: Color(0xFFDC2626), value: 0.9);
    }
  }

  List<String> _additionalDetails(SymptomModel model, AnalysisResult? res) {
    final details = <String>[];

    if (res == null) {
      details.add('Start a chat to generate a summary.');
      return details;
    }

    final keys = res.matchedKeys;
    if (keys.isNotEmpty) {
      details.add('Recognized: ${keys.join(', ')}');
    }

    if (keys.contains('fever')) {
      details.add('Monitor temperature and rest.');
    }
    if (keys.contains('cough')) {
      details.add('Hydrate and consider warm fluids.');
    }
    if (keys.contains('breath') || keys.contains('chest') || res.urgency == Urgency.high) {
      details.add('If symptoms worsen, seek urgent care.');
    }

    // A simple heuristic: if the last user message contains time words, show it.
    final lastUser = model.messages.lastWhere((m) => m.isUser, orElse: () => ChatMessage(''));
    final txt = lastUser.text.toLowerCase();
    if (txt.contains('day') || txt.contains('days') || txt.contains('week') || txt.contains('weeks')) {
      details.add('Reported timing: "${lastUser.text.trim()}"');
    }

    return details.take(4).toList(growable: false);
  }

  String _assistantNote(AnalysisResult? res) {
    if (res == null) {
      return '"The information above is based on our chat. Please describe your symptoms to generate a health summary."';
    }
    return '"${res.summary}"';
  }

  String _exportText(_ProfileSnapshot p, List<String> complaints, _Feeling feeling, List<String> details, AnalysisResult? res) {
    final b = StringBuffer();
    b.writeln('MediMitra — AI Health Summary');
    b.writeln('ID: ${p.reportId}');
    b.writeln('Date: ${p.reportDateLabel}');
    b.writeln('');
    b.writeln('Profile Summary');
    b.writeln('- Age: ${p.ageLabel}');
    b.writeln('- Gender: ${p.genderLabel}');
    b.writeln('- Medical History: ${p.medicalHistoryLabel}');
    b.writeln('');
    b.writeln('Main Complaints');
    if (complaints.isEmpty) {
      b.writeln('- (No complaints captured yet)');
    } else {
      for (final c in complaints) {
        b.writeln('- $c');
      }
    }
    b.writeln('');
    b.writeln('Overall Feeling');
    b.writeln('- ${feeling.label}');
    b.writeln('');
    b.writeln('Additional Details');
    for (final d in details) {
      b.writeln('- $d');
    }
    b.writeln('');
    b.writeln('Assistant Notes');
    b.writeln(_assistantNote(res));
    b.writeln('');
    b.writeln('IMPORTANT');
    b.writeln('MediMitra helps you organize your health thoughts. It does not provide medical advice. Always talk to a real doctor for health concerns. Do not ignore professional advice because of this summary.');
    return b.toString();
  }

  Future<Uint8List> _buildPdfBytes({
    required _ProfileSnapshot profile,
    required List<String> complaints,
    required _Feeling feeling,
    required List<String> details,
    required AnalysisResult? analysis,
  }) async {
    final doc = pw.Document();

    pw.Widget sectionTitle(String title) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
      );
    }

    pw.Widget kvRow(String k, String v) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                k,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                v,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey900),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget bullet(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Container(
                width: 6,
                height: 6,
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800, shape: pw.BoxShape.circle),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 11))),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        build: (context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MediMitra',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2EA1B8),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('AI Health Summary', style: pw.TextStyle(fontSize: 13, color: PdfColors.blueGrey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ID: ${profile.reportId}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(profile.reportDateLabel, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.blueGrey200),

            sectionTitle('Profile Summary'),
            kvRow('Age', profile.ageLabel),
            kvRow('Gender', profile.genderLabel),
            kvRow('Medical History', profile.medicalHistoryLabel),

            sectionTitle('Main Complaints'),
            if (complaints.isEmpty)
              bullet('(No complaints captured yet)')
            else
              ...complaints.map(bullet),

            sectionTitle('How you feel'),
            kvRow('Overall feeling', feeling.label),
            if (analysis != null)
              kvRow(
                'Urgency / Confidence',
                '${analysis.urgency.name.toUpperCase()} / ${(analysis.confidence * 100).toStringAsFixed(0)}%',
              ),

            sectionTitle('Additional Details'),
            ...details.map(bullet),

            sectionTitle('Assistant Notes'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE6F6F8),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFBFE8EE)),
              ),
              child: pw.Text(
                _assistantNote(analysis),
                style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.blueGrey900),
              ),
            ),

            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('IMPORTANT', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'MediMitra helps you organize your health thoughts. It does not provide medical advice. Always talk to a real doctor for health concerns. Do not ignore professional advice because of this summary.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey700),
                  ),
                ],
              ),
            ),
          ];
        },
        footer: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey600),
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _sharePdf({
    required _ProfileSnapshot profile,
    required List<String> complaints,
    required _Feeling feeling,
    required List<String> details,
    required AnalysisResult? analysis,
  }) async {
    try {
      final bytes = await _buildPdfBytes(
        profile: profile,
        complaints: complaints,
        feeling: feeling,
        details: details,
        analysis: analysis,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'MediMitra_Health_Summary_${profile.reportId}.pdf');
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF sharing needs a full app restart after adding the plugin. Stop the app and run again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171A) : const Color(0xFFF0F7F9),
      body: SafeArea(
        child: FutureBuilder<_ProfileSnapshot>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;

            return Consumer<SymptomModel>(
              builder: (context, model, _) {
                final res = _latestAnalysis(model);
                final complaints = _complaintsFromChat(model);
                final feeling = _feelingFromAnalysis(res);
                final details = _additionalDetails(model, res);

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: isDark ? const Color(0xFF0F171A).withOpacity(0.92) : Colors.white.withOpacity(0.92),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      title: Text(
                        'Health Summary',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Share PDF',
                          icon: Icon(Icons.picture_as_pdf_rounded, color: const Color(0xFF2EA1B8)),
                          onPressed: profile == null
                              ? null
                              : () => _sharePdf(
                                    profile: profile,
                                    complaints: complaints,
                                    feeling: feeling,
                                    details: details,
                                    analysis: res,
                                  ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),

                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (profile == null) ...[
                                  const SizedBox(height: 24),
                                  const Center(child: CircularProgressIndicator()),
                                ] else ...[
                                  _Header(profile: profile),
                                  const SizedBox(height: 18),

                                  _SectionTitle(icon: Icons.account_circle_rounded, title: 'Profile Summary'),
                                  const SizedBox(height: 10),
                                  _Card(
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _DataField(label: 'Age', value: profile.ageLabel),
                                            ),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: _DataField(label: 'Gender', value: profile.genderLabel),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Divider(height: 1, thickness: 1, color: (isDark ? Colors.white12 : Colors.black12.withOpacity(0.06))),
                                        const SizedBox(height: 14),
                                        _DataField(
                                          label: 'Medical History',
                                          value: profile.medicalHistoryLabel,
                                          valueColor: const Color(0xFF2EA1B8),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 22),
                                  _SectionTitle(icon: Icons.medical_information_rounded, title: 'Main Complaints'),
                                  const SizedBox(height: 10),
                                  _Card(
                                    child: complaints.isEmpty
                                        ? Text(
                                            'No chat history yet. Start chatting to generate your summary.',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              for (var i = 0; i < complaints.length; i++)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: i == complaints.length - 1 ? 0 : 12),
                                                  child: _Bullet(text: complaints[i], icon: Icons.check_circle_rounded),
                                                ),
                                            ],
                                          ),
                                  ),

                                  const SizedBox(height: 22),
                                  _SectionTitle(icon: Icons.mood_rounded, title: 'How you feel'),
                                  const SizedBox(height: 10),
                                  _Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _LabelValue(label: 'Overall feeling', value: feeling.label, valueColor: feeling.color),
                                        const SizedBox(height: 10),
                                        _ProgressBar(value: feeling.value, color: feeling.color),
                                        if (res != null) ...[
                                          const SizedBox(height: 14),
                                          Text(
                                            'Urgency: ${res.urgency.name.toUpperCase()} · Confidence: ${(res.confidence * 100).toStringAsFixed(0)}%',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 22),
                                  _SectionTitle(icon: Icons.note_add_rounded, title: 'Additional Details'),
                                  const SizedBox(height: 10),
                                  _Card(
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < details.length; i++)
                                          Padding(
                                            padding: EdgeInsets.only(bottom: i == details.length - 1 ? 0 : 12),
                                            child: _Bullet(text: details[i], icon: Icons.info_rounded, subtle: true),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 22),
                                  _SectionTitle(icon: Icons.auto_awesome_rounded, title: 'Assistant Notes'),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2EA1B8).withOpacity(isDark ? 0.16 : 0.10),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFF2EA1B8).withOpacity(isDark ? 0.20 : 0.18)),
                                    ),
                                    child: Text(
                                      _assistantNote(res),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                        color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.gavel_rounded, size: 18, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                            const SizedBox(width: 8),
                                            Text(
                                              'IMPORTANT',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                letterSpacing: 1.4,
                                                fontWeight: FontWeight.w900,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'MediMitra helps you organize your health thoughts. It does not provide medical advice. Always talk to a real doctor for health concerns. Do not ignore professional advice because of this summary.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            height: 1.35,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<_ProfileSnapshot>(
        future: _profileFuture,
        builder: (context, snap) {
          final profile = snap.data;
          if (profile == null) return const SizedBox.shrink();

          final model = context.watch<SymptomModel>();
          final res = _latestAnalysis(model);
          final complaints = _complaintsFromChat(model);
          final feeling = _feelingFromAnalysis(res);
          final details = _additionalDetails(model, res);

          return FloatingActionButton.extended(
            heroTag: 'ai_health_export',
            backgroundColor: const Color(0xFF2EA1B8),
            foregroundColor: Colors.white,
            onPressed: () => _sharePdf(
              profile: profile,
              complaints: complaints,
              feeling: feeling,
              details: details,
              analysis: res,
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export'),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final _ProfileSnapshot profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1114) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12.withOpacity(0.08)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2EA1B8).withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF2EA1B8), size: 34),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MediMitra',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2EA1B8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${profile.reportId}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              Text(
                profile.reportDateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2EA1B8), size: 22),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1114) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _DataField extends StatelessWidget {
  const _DataField({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon, this.subtle = false});

  final String text;
  final IconData icon;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 20, color: const Color(0xFF2EA1B8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: subtle ? (isDark ? Colors.white70 : const Color(0xFF475569)) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: isDark ? Colors.white10 : Colors.black12.withOpacity(0.06),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    required this.reportId,
    required this.reportDateLabel,
    required this.ageLabel,
    required this.genderLabel,
    required this.medicalHistoryLabel,
  });

  final String reportId;
  final String reportDateLabel;
  final String ageLabel;
  final String genderLabel;
  final String medicalHistoryLabel;
}

class _Feeling {
  const _Feeling({required this.label, required this.color, required this.value});

  final String label;
  final Color color;
  final double value;
}
