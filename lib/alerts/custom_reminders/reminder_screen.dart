// reminder_screen.dart
// lib/alerts/custom_reminders/reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reminder_model.dart';
import 'reminder_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../models/invoice_data.dart' show SavedInvoice;
import '../../models/quote_data.dart' show SavedQuote;

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderSheet(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Reminder'),
      ),
      body: reminders.isEmpty
          ? _EmptyState(onAdd: () => _showAddReminderSheet(context))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, i) => _ReminderCard(reminder: reminders[i]),
            ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddReminderSheet(),
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
            Icon(Icons.alarm_add_rounded, size: 48, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No reminders yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a reminder for a client follow-up, a call, or anything not tied to an invoice due date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
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
  const _ReminderCard({required this.reminder});

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
          color: const Color(0xFFD32F2F).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F)),
      ),
      onDismissed: (_) => context.read<ReminderProvider>().deleteReminder(reminder.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
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
                  Text(reminder.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (reminder.note.isNotEmpty)
                    Text(reminder.note,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
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
          ],
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

// A single entry in the "Link to" dropdown — either a saved invoice or a
// saved quote. Encoded as a "type:id" key string since DropdownButtonFormField
// needs a value type with stable equality, and String already has that.
class _LinkOption {
  final LinkedDocumentType type;
  final String id;
  final String label;
  _LinkOption({required this.type, required this.id, required this.label});

  String get key => '${type.name}:$id';
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _notifyPush = true;
  String? _selectedLinkKey;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  List<_LinkOption> _buildLinkOptions(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes = context.watch<QuoteProvider>().savedQuotes;

    final options = <_LinkOption>[
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
    return options;
  }

  void _save(List<_LinkOption> linkOptions) {
    if (_titleController.text.trim().isEmpty) return;
    final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

    _LinkOption? selected;
    if (_selectedLinkKey != null) {
      try {
        selected = linkOptions.firstWhere((o) => o.key == _selectedLinkKey);
      } catch (_) {
        selected = null;
      }
    }

    context.read<ReminderProvider>().addReminder(
          title: _titleController.text.trim(),
          note: _noteController.text.trim(),
          remindAt: scheduled,
          notifyPush: _notifyPush,
          linkedDocumentId: selected?.id,
          linkedDocumentType: selected?.type,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final linkOptions = _buildLinkOptions(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        // Whichever is taller: keyboard covering the sheet, or the phone's
        // own bottom gesture-nav inset when the keyboard's closed. Using
        // just viewInsets.bottom left the Save button hidden behind the
        // nav bar on gesture-nav devices.
        bottom: (keyboardInset > safeBottom ? keyboardInset : safeBottom) + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Follow up with Acme Co.'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedLinkKey,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Link to (optional)',
              prefixIcon: Icon(Icons.link_rounded, size: 20),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
              ...linkOptions.map(
                (o) => DropdownMenuItem<String?>(
                  value: o.key,
                  child: Text(o.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedLinkKey = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Push notification'),
            subtitle: const Text('Alert me even if the app is closed'),
            value: _notifyPush,
            onChanged: (v) => setState(() => _notifyPush = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => _save(linkOptions), child: const Text('Save Reminder')),
          ),
        ],
      ),
    );
  }
}
