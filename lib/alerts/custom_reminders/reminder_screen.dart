// reminder_screen.dart
// lib/alerts/custom_reminders/reminder_screen.dart
//
// HIGHLIGHT ON ARRIVAL (earlier pass): RemindersScreen takes an optional
// highlightReminderId, set when the user arrives here by tapping a
// notification. The matching card gets a 3-second colored-border flash,
// then fades back to normal.
//
// VALIDATION + UNDO (earlier pass): the form rejects an empty title and a
// past date/time with inline errors. Deleting a non-recurring reminder
// offers Undo via ReminderProvider.restoreReminder().
//
// PERMISSION BANNER (earlier pass): if OS-level notification permission is
// off, the form shows a small warning so the user knows push won't fire —
// the reminder still saves and still shows in-app either way.
//
// EDIT (this pass): tapping a reminder card now opens the same form
// pre-filled for editing (_ReminderFormSheet takes an optional `existing`
// reminder) instead of only being able to delete and recreate it.
//
// RECURRENCE (this pass): a Wrap of choice chips (Once / Daily / Weekly /
// Monthly) lets a reminder repeat. Swiping away a recurring reminder
// advances it to its next occurrence instead of deleting the series —
// only a non-recurring reminder (or explicit delete) actually goes away
// with an Undo option. A small "↻ Weekly" style badge shows on recurring
// cards so it's clear at a glance which ones repeat.
//
// SEARCHABLE LINK PICKER (this pass): the "Link to" field used to be a
// plain dropdown, unusable once someone has 50+ saved documents. It's now
// a tap-to-open bottom sheet with a search field that filters invoices and
// quotes by title/client as you type.
//
// NOTE COUNTER (this pass): the note field now caps at 200 characters with
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
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderForm(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Reminder'),
      ),
      body: reminders.isEmpty
          ? _EmptyState(onAdd: () => _showReminderForm(context))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, i) => _ReminderCard(
                reminder: reminders[i],
                highlighted: reminders[i].id == _highlightId,
              ),
            ),
    );
  }

  void _showReminderForm(BuildContext context, {CustomReminder? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Icon(Icons.alarm_add_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No reminders yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a reminder for a client follow-up, a call, or anything not tied to an invoice due date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
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

class _ReminderCard extends StatelessWidget {
  final CustomReminder reminder;
  final bool highlighted;
  const _ReminderCard({required this.reminder, this.highlighted = false});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = reminder.isDue ? const Color(0xFFD32F2F) : const Color(0xFF2196F3);
    final linkedLabel = _linkedDocumentLabel(context, reminder);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          reminder.isRecurring ? Icons.repeat_rounded : Icons.delete_outline_rounded,
          color: const Color(0xFFD32F2F),
        ),
      ),
      onDismissed: (_) => _handleDismiss(context),
      child: GestureDetector(
        onTap: () => _openEdit(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? color : cs.outline.withValues(alpha: 0.2),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: highlighted
                ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  reminder.isDue ? Icons.notifications_active_rounded : Icons.schedule_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(reminder.title,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (reminder.isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
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
                    if (reminder.note.isNotEmpty)
                      Text(reminder.note,
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (linkedLabel != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            reminder.linkedDocumentType == LinkedDocumentType.invoice
                                ? Icons.receipt_long_rounded
                                : Icons.description_rounded,
                            size: 12,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(linkedLabel,
                                style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(_formatDateTime(reminder.remindAt),
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
            ],
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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Padding(
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
            Text('Link to a document', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search invoices & quotes',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: const Icon(Icons.link_off_rounded),
                    title: const Text('None'),
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
                      ListTile(
                        leading: Icon(
                          o.type == LinkedDocumentType.invoice
                              ? Icons.receipt_long_rounded
                              : Icons.description_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                        title: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, o.key),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit form ──────────────────────────────────────────────────────

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
            child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  Widget _linkPickerField(List<_LinkOption> options) {
    final selected = options.where((o) => o.key == _selectedLinkKey);
    final label = selected.isEmpty ? 'None' : selected.first.label;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openLinkPicker(options),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Link to (optional)',
          prefixIcon: Icon(Icons.link_rounded, size: 20),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.unfold_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _recurrenceSelector() {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReminderRecurrence.values.map((r) {
        final selected = _recurrence == r;
        return ChoiceChip(
          label: Text(r.shortLabel),
          selected: selected,
          onSelected: (_) => setState(() => _recurrence = r),
          selectedColor: cs.primary,
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
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

    return Padding(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Edit Reminder' : 'New Reminder',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.isEditing)
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F)),
                    tooltip: 'Delete',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Follow up with Acme Co.',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
              maxLength: 200,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            if (_timeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _timeError!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'REPEAT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: cs.primary),
            ),
            const SizedBox(height: 8),
            _recurrenceSelector(),
            const SizedBox(height: 14),
            _linkPickerField(linkOptions),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push notification'),
              subtitle: const Text('Alert me even if the app is closed'),
              value: _notifyPush,
              onChanged: (v) => setState(() => _notifyPush = v),
            ),
            if (_pushPermissionDenied && _notifyPush)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF57C00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF57C00)),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _save(linkOptions),
                child: Text(widget.isEditing ? 'Save Changes' : 'Save Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
