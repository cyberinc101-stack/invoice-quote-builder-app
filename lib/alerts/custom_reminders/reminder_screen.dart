// reminder_screen.dart
// lib/alerts/custom_reminders/reminder_screen.dart
//
// HOME UI-PARITY PASS (this update): visual-only change, no data/logic
// changes. This screen already used cs.primary/cs.error throughout
// (see the THEME OVERHAUL pass below) so it was mostly there already —
// the one piece still out of step with Home/Reports/Alerts was the
// Scaffold's custom backgroundColor and the AppBar's custom elevation/
// background/foreground/centerTitle tuning. Both are now dropped so this
// screen inherits the same defaults Home, Reports, and Alerts all use.
// There's no stats/controls strip here worth promoting into an
// AppHeroCard (unlike Alerts' stats+filter row or Reports' period/
// folder/toggle row) — the reminders list is the whole screen — so no
// hero card was introduced here, just the chrome alignment.
//
// THEME OVERHAUL (earlier pass): restyled to match the flat, grouped-list
// look introduced on alerts_screen.dart — reminders wrapped in a single
// rounded card with hairline dividers between rows instead of separately
// floating cards, and the hardcoded blue (0xFF2196F3) / red (0xFFD32F2F)
// swapped for the app's actual ColorScheme (cs.primary / cs.error) so
// this screen reads as part of the same design system as the rest of the
// app instead of a visually separate one. The "New Reminder" FAB, the
// recurrence chips, the link-picker sheet, and the add/edit form sheet
// all got the same treatment: cs.primary for accents, flat bordered
// fields instead of heavy fills, muted secondary text.
//
// No behavioral changes from the previous pass — same highlight-on-
// arrival flash, same validation + Undo, same permission banner, same
// edit-on-tap, same recurrence chips, same searchable link picker, same
// note character counter.
//
// HIGHLIGHT ON ARRIVAL (earlier pass): RemindersScreen takes an optional
// highlightReminderId, set when the user arrives here by tapping a
// notification. The matching card gets a colored-border flash, then
// fades back to normal.
//
// VALIDATION + UNDO (earlier pass): the form rejects an empty title and a
// past date/time with inline errors. Deleting a non-recurring reminder
// offers Undo via ReminderProvider.restoreReminder().
//
// PERMISSION BANNER (earlier pass): if OS-level notification permission is
// off, the form shows a small warning so the user knows push won't fire —
// the reminder still saves and still shows in-app either way.
//
// EDIT (earlier pass): tapping a reminder card opens the same form
// pre-filled for editing (_ReminderFormSheet takes an optional `existing`
// reminder) instead of only being able to delete and recreate it.
//
// RECURRENCE (earlier pass): a Wrap of choice chips (Once / Daily / Weekly
// / Monthly) lets a reminder repeat. Swiping away a recurring reminder
// advances it to its next occurrence instead of deleting the series —
// only a non-recurring reminder (or explicit delete) actually goes away
// with an Undo option.
//
// SEARCHABLE LINK PICKER (earlier pass): the "Link to" field is a
// tap-to-open bottom sheet with a search field that filters invoices and
// quotes by title/client as you type.
//
// NOTE COUNTER (earlier pass): the note field caps at 200 characters with
// Flutter's built-in maxLength counter shown beneath it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reminder_model.dart';
import 'reminder_provider.dart';
import '../notifications/notification_service.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../models/invoice_data.dart' show SavedInvoice;
import '../../models/quote_data.dart' show SavedQuote;

// Sentinel used by the link picker sheet to distinguish "user explicitly
// chose None" from "sheet was dismissed without a choice" — both would
// otherwise look like a null return value.
const String _kNoneLinkKey = '__none__';

class RemindersScreen extends StatefulWidget {
  final String? highlightReminderId;
  const RemindersScreen({super.key, this.highlightReminderId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String? _highlightId;

  @override
  void initState() {
    super.initState();
    _highlightId = widget.highlightReminderId;
    if (_highlightId != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      // Plain default (theme) AppBar/Scaffold background — matches
      // HomeScreen's, ReportsScreen's, and AlertsScreen's, instead of
      // the previous custom elevation/background/foreground tuning.
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderForm(context),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: reminders.isEmpty
          ? _EmptyState(onAdd: () => _showReminderForm(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _RemindersCardGroup(
                  reminders: reminders,
                  highlightId: _highlightId,
                ),
              ],
            ),
    );
  }

  void _showReminderForm(BuildContext context, {CustomReminder? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderFormSheet(existing: existing),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.alarm_add_rounded, size: 28, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a reminder for a client follow-up, a call, or anything not tied to an invoice due date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.primary),
              onPressed: onAdd,
              child: const Text('New Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

// Resolves a reminder's linked invoice/quote title for display. Looked up
// live each build so a rename of the linked document stays in sync — we
// only ever store the id + type on the reminder, never a copied title.
String? _linkedDocumentLabel(BuildContext context, CustomReminder reminder) {
  if (!reminder.hasLinkedDocument) return null;
  if (reminder.linkedDocumentType == LinkedDocumentType.invoice) {
    final inv = context.read<InvoiceProvider>().getInvoiceById(reminder.linkedDocumentId!);
    if (inv == null) return null;
    final client = inv.data.clientName;
    return client.isEmpty ? inv.title : '${inv.title} · $client';
  } else {
    final q = context.read<QuoteProvider>().getQuoteById(reminder.linkedDocumentId!);
    if (q == null) return null;
    final client = q.data.clientName;
    return client.isEmpty ? q.title : '${q.title} · $client';
  }
}

// Groups every reminder into a single rounded surface with hairline
// dividers between rows — matches _CardGroup on alerts_screen.dart,
// instead of each reminder floating as its own separately-shadowed card.
class _RemindersCardGroup extends StatelessWidget {
  final List<CustomReminder> reminders;
  final String? highlightId;
  const _RemindersCardGroup({required this.reminders, required this.highlightId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < reminders.length; i++) ...[
            _ReminderRow(
              reminder: reminders[i],
              highlighted: reminders[i].id == highlightId,
            ),
            if (i != reminders.length - 1)
              Divider(height: 1, thickness: 1, indent: 62, color: cs.outline.withValues(alpha: 0.1)),
          ],
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final CustomReminder reminder;
  final bool highlighted;
  const _ReminderRow({required this.reminder, this.highlighted = false});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderFormSheet(existing: reminder),
    );
  }

  void _handleDismiss(BuildContext context) {
    if (reminder.isRecurring) {
      // Recurring reminders never fully disappear on a swipe — they move
      // to their next occurrence, same as marking today's copy "done".
      context.read<ReminderProvider>().advanceRecurringReminder(reminder.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${reminder.title}" moved to its next occurrence'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final removed = reminder;
      context.read<ReminderProvider>().deleteReminder(reminder.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${removed.title}" deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => context.read<ReminderProvider>().restoreReminder(removed),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Due reminders use the app's error color (urgent, unmissable); not-yet-
    // due reminders use the app's own primary accent (cs.primary) instead
    // of a hardcoded blue, so this matches whatever brand color the rest
    // of the app is themed with.
    final color = reminder.isDue ? cs.error : cs.primary;
    final linkedLabel = _linkedDocumentLabel(context, reminder);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error.withValues(alpha: 0.1),
        child: Icon(
          reminder.isRecurring ? Icons.repeat_rounded : Icons.delete_outline_rounded,
          color: cs.error,
          size: 20,
        ),
      ),
      onDismissed: (_) => _handleDismiss(context),
      child: Material(
        color: highlighted ? color.withValues(alpha: 0.06) : Colors.transparent,
        child: InkWell(
          onTap: () => _openEdit(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: highlighted
                ? BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(12))
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(
                    reminder.isDue ? Icons.notifications_active_rounded : Icons.schedule_rounded,
                    color: color,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(reminder.title,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (reminder.isRecurring) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded, size: 10, color: cs.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    reminder.recurrence.shortLabel,
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: cs.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (reminder.note.isNotEmpty)
                        Text(reminder.note,
                            style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.5)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (linkedLabel != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              reminder.linkedDocumentType == LinkedDocumentType.invoice
                                  ? Icons.receipt_long_rounded
                                  : Icons.description_rounded,
                              size: 11,
                              color: cs.onSurface.withValues(alpha: 0.32),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(linkedLabel,
                                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(_formatDateTime(reminder.remindAt),
                          style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} · $hour:$minute $period';
  }
}

// A single entry in the "Link to" picker — either a saved invoice or a
// saved quote. Encoded as a "type:id" key string for stable equality.
class _LinkOption {
  final LinkedDocumentType type;
  final String id;
  final String label;
  _LinkOption({required this.type, required this.id, required this.label});

  String get key => '${type.name}:$id';
}

// ── Searchable link picker sheet ──────────────────────────────────────
// Restyled to match the flat, professional look — rounded search field
// with a subtle border instead of the default filled TextField, list rows
// with a small icon circle (cs.primary tint) instead of a bare icon.

class _LinkPickerSheet extends StatefulWidget {
  final List<_LinkOption> options;
  const _LinkPickerSheet({required this.options});

  @override
  State<_LinkPickerSheet> createState() => _LinkPickerSheetState();
}

class _LinkPickerSheetState extends State<_LinkPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.options
        : widget.options.where((o) => o.label.toLowerCase().contains(_query.trim().toLowerCase())).toList();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F8FA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Link to a document', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2235) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search invoices & quotes',
                    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2235) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _LinkRow(
                        icon: Icons.link_off_rounded,
                        iconColor: cs.onSurface.withValues(alpha: 0.4),
                        label: 'None',
                        onTap: () => Navigator.pop(context, _kNoneLinkKey),
                      ),
                      if (widget.options.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No saved invoices or quotes yet',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No matches', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
                          ),
                        )
                      else
                        for (final o in filtered)
                          _LinkRow(
                            icon: o.type == LinkedDocumentType.invoice
                                ? Icons.receipt_long_rounded
                                : Icons.description_rounded,
                            iconColor: cs.primary,
                            label: o.label,
                            onTap: () => Navigator.pop(context, o.key),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add / Edit form ──────────────────────────────────────────────────────
// Restyled bottom sheet: rounded top surface (matching the app's other
// sheets — folder picker, export sheet, display options), a small drag
// handle, bordered flat fields instead of filled Material defaults, and
// cs.primary for every accent (Save button, section labels, recurrence
// chips, linked-document icon) instead of the previous hardcoded colors.

class _ReminderFormSheet extends StatefulWidget {
  final CustomReminder? existing;
  const _ReminderFormSheet({this.existing});

  bool get isEditing => existing != null;

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late TimeOfDay _time;
  late bool _notifyPush;
  late ReminderRecurrence _recurrence;
  String? _selectedLinkKey;

  String? _titleError;
  String? _timeError;
  bool _pushPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _date = existing?.remindAt ?? DateTime.now().add(const Duration(days: 1));
    _time = existing != null
        ? TimeOfDay(hour: existing.remindAt.hour, minute: existing.remindAt.minute)
        : const TimeOfDay(hour: 9, minute: 0);
    _notifyPush = existing?.notifyPush ?? true;
    _recurrence = existing?.recurrence ?? ReminderRecurrence.none;
    _selectedLinkKey = existing != null && existing.hasLinkedDocument
        ? '${existing.linkedDocumentType!.name}:${existing.linkedDocumentId}'
        : null;
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final enabled = await NotificationService.instance.notificationsEnabled;
    if (mounted && !enabled) {
      setState(() => _pushPermissionDenied = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _timeError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeError = null;
      });
    }
  }

  List<_LinkOption> _buildLinkOptions(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes = context.watch<QuoteProvider>().savedQuotes;

    return <_LinkOption>[
      ...invoices.map((SavedInvoice inv) => _LinkOption(
            type: LinkedDocumentType.invoice,
            id: inv.id,
            label: inv.data.clientName.isEmpty
                ? 'Invoice · ${inv.title}'
                : 'Invoice · ${inv.title} (${inv.data.clientName})',
          )),
      ...quotes.map((SavedQuote q) => _LinkOption(
            type: LinkedDocumentType.quote,
            id: q.id,
            label: q.data.clientName.isEmpty
                ? 'Quote · ${q.title}'
                : 'Quote · ${q.title} (${q.data.clientName})',
          )),
    ];
  }

  Future<void> _openLinkPicker(List<_LinkOption> options) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkPickerSheet(options: options),
    );
    if (picked == null) return; // sheet dismissed without a choice
    setState(() => _selectedLinkKey = picked == _kNoneLinkKey ? null : picked);
  }

  void _save(List<_LinkOption> linkOptions) {
    final title = _titleController.text.trim();
    final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final isPast = !scheduled.isAfter(DateTime.now());

    setState(() {
      _titleError = title.isEmpty ? 'Give this reminder a title' : null;
      _timeError = isPast ? 'Pick a date and time in the future' : null;
    });
    if (title.isEmpty || isPast) return;

    _LinkOption? selected;
    if (_selectedLinkKey != null) {
      try {
        selected = linkOptions.firstWhere((o) => o.key == _selectedLinkKey);
      } catch (_) {
        selected = null;
      }
    }

    final provider = context.read<ReminderProvider>();
    if (widget.isEditing) {
      provider.updateReminder(
        widget.existing!.id,
        title: title,
        note: _noteController.text.trim(),
        remindAt: scheduled,
        notifyPush: _notifyPush,
        linkedDocumentId: selected?.id,
        linkedDocumentType: selected?.type,
        recurrence: _recurrence,
      );
    } else {
      provider.addReminder(
        title: title,
        note: _noteController.text.trim(),
        remindAt: scheduled,
        notifyPush: _notifyPush,
        linkedDocumentId: selected?.id,
        linkedDocumentType: selected?.type,
        recurrence: _recurrence,
      );
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    final existing = widget.existing;
    if (existing == null) return;
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text(
          existing.isRecurring
              ? 'This will delete the whole repeating series, not just the next occurrence.'
              : 'This can\'t be undone from here.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ReminderProvider>().deleteReminder(existing.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: cs.onSurface.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _borderedField({required Widget child, required ColorScheme cs, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }

  Widget _linkPickerField(List<_LinkOption> options, ColorScheme cs, bool isDark) {
    final selected = options.where((o) => o.key == _selectedLinkKey);
    final label = selected.isEmpty ? 'None' : selected.first.label;
    return _borderedField(
      cs: cs,
      isDark: isDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLinkPicker(options),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 13.5, color: cs.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.unfold_more_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recurrenceSelector(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReminderRecurrence.values.map((r) {
        final selected = _recurrence == r;
        return GestureDetector(
          onTap: () => setState(() => _recurrence = r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.25)),
            ),
            child: Text(
              r.shortLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final linkOptions = _buildLinkOptions(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F8FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          // Whichever is taller: keyboard covering the sheet, or the phone's
          // own bottom gesture-nav inset when the keyboard's closed.
          bottom: (keyboardInset > safeBottom ? keyboardInset : safeBottom) + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Edit Reminder' : 'New Reminder',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface),
                    ),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                      tooltip: 'Delete',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _fieldLabel('Title', cs),
              _borderedField(
                cs: cs,
                isDark: isDark,
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'e.g. Follow up with Acme Co.',
                    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
                    errorText: _titleError,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  onChanged: (_) {
                    if (_titleError != null) setState(() => _titleError = null);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Note (optional)', cs),
              _borderedField(
                cs: cs,
                isDark: isDark,
                child: TextField(
                  controller: _noteController,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _borderedField(
                      cs: cs,
                      isDark: isDark,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 15, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('${_date.day}/${_date.month}/${_date.year}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _borderedField(
                      cs: cs,
                      isDark: isDark,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickTime,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time_rounded, size: 15, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(_time.format(context),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(_timeError!, style: TextStyle(fontSize: 12, color: cs.error)),
                ),
              const SizedBox(height: 16),
              _fieldLabel('Repeat', cs),
              _recurrenceSelector(cs),
              const SizedBox(height: 16),
              _fieldLabel('Link to (optional)', cs),
              _linkPickerField(linkOptions, cs, isDark),
              const SizedBox(height: 10),
              _borderedField(
                cs: cs,
                isDark: isDark,
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  title: Text('Push notification', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text('Alert me even if the app is closed',
                      style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.45))),
                  value: _notifyPush,
                  activeThumbColor: cs.primary,
                  onChanged: (v) => setState(() => _notifyPush = v),
                ),
              ),
              if (_pushPermissionDenied && _notifyPush)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB26A00).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB26A00).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB26A00)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Notifications are turned off for this app in system settings, so push won't fire — this reminder will still show up in-app.",
                          style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _save(linkOptions),
                  child: Text(
                    widget.isEditing ? 'Save Changes' : 'Save Reminder',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
