// doc_kanban.dart
// lib/widgets/saved_documents/doc_kanban.dart
//
// Part of saved_documents_section.dart — the kanban board layout.
//
// FOLDER-GROUPING PASS (this update): the client-grouped board
// (_DocKanbanBoardByClient) now groups an Expense entry by its assigned
// folderName when one is set, instead of always grouping by vendor
// (businessName). Previously an expense moved into a folder that shared
// a name with an existing client column (e.g. "Acme Corp") would still
// render in its own separate vendor-named column, or in the standalone
// "My Expenses" section below the whole board -- never inside "Acme
// Corp"'s column where the invoices/quotes/receipts for that folder
// already live. Since expenses exist purely as a "dummy container" for
// accounting accuracy (see saved_documents_section.dart's expenseDocEntries
// comment), the folder assignment IS the intended client grouping for an
// expense -- vendor is only the fallback when no folder has been set yet.
// Invoice/Quote/Receipt entries are unaffected: they still group by
// businessName exactly as before, since their own "convert this column to
// a folder" flow is what assigns folderName in the first place, and
// changing their grouping key too would be a bigger behavioural shift
// than this fix calls for.
//
// typeOrder in _DocKanbanClientColumn gained 'Expense' (rendered last,
// after Receipts) so a column containing folder-assigned expenses shows
// an EXPENSES sub-header the same way it already shows INVOICES / QUOTES
// / RECEIPTS -- matching the request that a folder-assigned expense
// "shows in the folder container at the bottom of receipts section were
// invoice, quotes and receipts show". _DocKanbanTypeHeader's color map
// gained a matching 'Expense': kExpenseAccent entry.
//
// CARD DISPLAY PREFS PASS (earlier): _DocKanbanCard now reads
// CardDisplayPrefs and gates the three fields it already renders — Logo,
// Amount, and the completion Progress Bar — behind their matching
// toggles, same as every other card layout. Previously this card ignored
// CardDisplayPrefs entirely (never called context.watch on it), so those
// three toggles silently had no effect here even though the sheet's copy
// ("applies everywhere") implied they did.
//
// Secondary Date, Created Date & Item Count, and Status Chip are
// deliberately NOT added here — none of the three currently render any
// UI on this card at all, and each column is only 165px wide with cards
// already carrying title, subtitle, date, and amount. Adding brand-new
// elements for those three toggles risks exactly the cramped, cluttered
// card this compact layout is meant to avoid; Kanban's card content
// stays its own fixed compact set (title/subtitle/date/amount, now each
// individually toggleable) rather than growing to match every field the
// larger layouts show. This mirrors how Card Style (Logo Banner) is
// already List-only by design — some display options only make sense at
// certain sizes.
//
// CLIENT-GROUPED BOARD (earlier pass): added _DocKanbanBoardByClient — an
// alternate grouping mode alongside the original status-grouped
// _DocKanbanBoard. Reachable via the "Group by: Status / Client" toggle
// in saved_documents_section.dart (only shown while Kanban is the active
// layout). Rather than three separate per-status boards split by document
// type (My Invoices / My Quotes / My Receipts each with their own board),
// this groups by CLIENT (businessName) across all three document types at
// once — mirrors how a CRM-style kanban typically works: "show me
// everything for Acme Corp" rather than "show me every unpaid invoice,
// regardless of client." Columns are client names; each card carries a
// small type badge (Invoice/Quote/Receipt) since a column can now mix
// document types, which the original status-grouped board never needed
// since each of its boards only ever held one type.
//
// Column header color: uses ClientColorPrefs.colorFor(clientName) when
// the user has assigned one (see client_color_prefs.dart) — same color
// that already tints that client's logo box elsewhere — falling back to
// a neutral grey dot when no color has been set, so this view reinforces
// the same client-color system rather than introducing a second one.
//
// Documents with an empty/blank businessName are grouped into a single
// "No Client" column at the end, rather than silently dropped or crashing
// on an empty map key.
//
// TYPE SUB-HEADERS (earlier pass): each client column now groups its
// cards into labeled sub-sections (Invoices / Quotes / Receipts, in that
// fixed order) instead of one flat mixed list with a per-card type badge.
// Each sub-section gets a tiny colored-bar header — a scaled-down version
// of the home screen's My Invoices / My Quotes / My Receipts
// SectionHeader — so a client column with mixed document types reads the
// same way the home screen itself does. The per-card type badge
// (showTypeBadge) is no longer used on the client-grouped board since the
// sub-header now carries that label; it's kept on _DocKanbanCard for the
// status-grouped board's potential future use but defaults off.
//
// FOLDER CONVERSION (earlier pass): each client column header now also
// has a small folder icon that opens a "Create Folder" sheet (implemented
// in saved_documents_section.dart, since it needs the
// Invoice/Quote/Receipt providers to actually write folderName onto each
// chosen document) — pre-filled with the client's name and that column's
// full document list, with per-document checkboxes to include/exclude
// before confirming.
//
// NEW (earlier pass): kanban cards now show the business logo via
// DocLogoAvatar (doc_card_shared.dart, 18x18 — smallest of any layout,
// this board is already the tightest on space) in place of the icon that
// used to sit where the title now starts flush-left, plus the document's
// total amount on its own small line. Created date / item count are
// skipped here — the column is only 165 wide and the card already carries
// title, subtitle, last-edited date, and a progress bar; adding two more
// lines would either overflow or force everything down to unreadable
// font sizes.
//
// SHRINK (earlier pass, kept): whole board scaled down — column width 165,
// card padding/fonts trimmed, board height 380. The 3-dot icon's own size
// lives in ThreeDotIcon (doc_card_shared.dart) which this file doesn't
// own, so it's wrapped in a Transform.scale here to shrink it in place
// without touching that shared widget.

part of 'saved_documents_section.dart';

// ─────────────────────────────────────────────────────────────────────────
// Status-grouped board (original) — one call per document type, from each
// of the My Invoices / My Quotes / My Receipts sections.
// ─────────────────────────────────────────────────────────────────────────

class _DocKanbanBoard extends StatelessWidget {
  final List<_DocEntry> entries;
  const _DocKanbanBoard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<_DocEntry>> columns = {};
    for (final e in entries) {
      columns.putIfAbsent(e.statusLabel, () => []).add(e);
    }

    return SizedBox(
      height: 380,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.entries
              .map((col) => _DocKanbanColumn(statusLabel: col.key, entries: col.value))
              .toList(),
        ),
      ),
    );
  }
}

class _DocKanbanColumn extends StatelessWidget {
  final String statusLabel;
  final List<_DocEntry> entries;
  const _DocKanbanColumn({required this.statusLabel, required this.entries});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = entries.isNotEmpty ? entries.first.accentColor : cs.primary;

    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) => _DocKanbanCard(entry: entries[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocKanbanCard extends StatelessWidget {
  final _DocEntry entry;
  final bool showTypeBadge;
  const _DocKanbanCard({required this.entry, this.showTypeBadge = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = context.watch<CardDisplayPrefs>();

    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prefs.showLogo) ...[
                  GestureDetector(
                    onLongPress: entry.onSetClientColor,
                    child: DocLogoAvatar(
                      logoPath: entry.logoPath,
                      logoOffset: entry.logoOffset,
                      logoScale: entry.logoScale,
                      logoShape: entry.logoShape,
                      businessName: entry.businessName,
                      accentColor: entry.accentColor,
                      clientColor: entry.clientColor,
                      size: 18,
                      iconSize: 10,
                      borderRadius: 6,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isPositiveStatus) positiveStatusDot(),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: ThreeDotIcon(onTap: entry.onShowMenu),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.subtitle,
                    style: TextStyle(fontSize: 9, color: entry.accentColor, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Type badge -- retained for the status-grouped board's
                // potential future use, but defaults off. The client-
                // grouped board no longer sets this to true; it uses
                // per-type sub-headers (_DocKanbanTypeHeader) instead,
                // since a column there can mix Invoice/Quote/Receipt/
                // Expense cards together and a header reads better than a
                // badge repeated on every card.
                if (showTypeBadge) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: entry.accentColor.withValues(alpha: kDocChipAlpha),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      entry.docTypeLabel,
                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: entry.accentColor),
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.date,
                    style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.4)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (prefs.showAmount)
                  Text(
                    _formatCardAmount(entry.totalAmount),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            if (prefs.showProgress) ...[
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: entry.percent / 100,
                  backgroundColor: cs.outline.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(entry.accentColor),
                  minHeight: 2.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Client-grouped board (this pass) — one combined board spanning
// Invoices + Quotes + Receipts + Expenses, columns = client instead of
// status. Caller (saved_documents_section.dart) is responsible for
// merging the entry lists before passing them in here.
// ─────────────────────────────────────────────────────────────────────────

const String _kNoClientLabel = 'No Client';

// Grouping key for a single entry in the client-grouped board.
//
// FOLDER-GROUPING PASS: an Expense entry with a non-empty folderName
// groups under that folder name instead of its vendor -- so an expense
// moved into (say) "Acme Corp"'s folder lands in the "Acme Corp" column
// alongside that client's invoices/quotes/receipts, rather than getting
// its own vendor-named column or being invisible to this board entirely.
// An expense with no folder assigned yet falls back to vendor
// (businessName), same as before this pass. Invoice/Quote/Receipt
// entries are untouched -- always grouped by businessName, since those
// three types don't carry a separate "grouping" concept distinct from
// their own client name.
String _clientGroupKey(_DocEntry e) {
  if (e.docTypeLabel == 'Expense') {
    final folder = e.folderName?.trim();
    if (folder != null && folder.isNotEmpty) return folder;
  }
  final name = e.businessName.trim();
  return name.isEmpty ? _kNoClientLabel : name;
}

class _DocKanbanBoardByClient extends StatelessWidget {
  final List<_DocEntry> entries;

  // Opens the "turn this column into a Folder" sheet (implemented in
  // saved_documents_section.dart, since it needs InvoiceProvider/
  // QuoteProvider/ReceiptProvider/ExpenseProvider to actually apply the
  // folder name to each chosen document) -- suggestedName defaults to
  // the column name, entries is that column's full document list so the
  // sheet can offer per-document include/exclude checkboxes before
  // creating the folder.
  final void Function(String suggestedName, List<_DocEntry> entries) onConvertToFolder;

  const _DocKanbanBoardByClient({required this.entries, required this.onConvertToFolder});

  @override
  Widget build(BuildContext context) {
    final clientColorPrefs = context.watch<ClientColorPrefs>();

    final Map<String, List<_DocEntry>> columns = {};
    for (final e in entries) {
      final key = _clientGroupKey(e);
      columns.putIfAbsent(key, () => []).add(e);
    }

    // No-Client column (if any) always sorts last; everything else stays
    // in the order Map insertion gave it (first-seen order among the
    // merged invoice/quote/receipt/expense lists), which is the same "no
    // particular order beyond source order" behaviour the status-grouped
    // board already has for its own columns.
    final orderedKeys = columns.keys.toList()
      ..sort((a, b) {
        if (a == _kNoClientLabel) return 1;
        if (b == _kNoClientLabel) return -1;
        return 0;
      });

    return SizedBox(
      height: 380,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: orderedKeys
              .map((clientName) => _DocKanbanClientColumn(
                    clientName: clientName,
                    entries: columns[clientName]!,
                    assignedColor:
                        clientName == _kNoClientLabel ? null : clientColorPrefs.colorFor(clientName),
                    onConvertToFolder: onConvertToFolder,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _DocKanbanClientColumn extends StatelessWidget {
  final String clientName;
  final List<_DocEntry> entries;
  final Color? assignedColor;
  final void Function(String suggestedName, List<_DocEntry> entries) onConvertToFolder;

  const _DocKanbanClientColumn({
    required this.clientName,
    required this.entries,
    required this.assignedColor,
    required this.onConvertToFolder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Falls back to a neutral grey dot (rather than an arbitrary
    // document's own accent, which would be misleading here -- this
    // column can mix Invoice/Quote/Receipt/Expense entries with
    // different accent colors) when the client has no color assigned yet.
    final dotColor = assignedColor ?? cs.onSurface.withValues(alpha: 0.35);

    // Group this column's cards by document type, in a fixed Invoice ->
    // Quote -> Receipt -> Expense order (matching the home screen's own
    // My Invoices / My Quotes / My Receipts / My Expenses section order),
    // rather than first-seen order, so the sub-headers appear in a
    // stable sequence no matter which document happened to be created
    // first for this client. Expense sits last -- see FOLDER-GROUPING
    // PASS above the file's part-of directive for why an expense can end
    // up in this column at all (folderName match) rather than only ever
    // living in its own vendor column.
    const typeOrder = ['Invoice', 'Quote', 'Receipt', 'Expense'];
    final Map<String, List<_DocEntry>> byType = {};
    for (final e in entries) {
      byType.putIfAbsent(e.docTypeLabel, () => []).add(e);
    }
    final orderedTypes = typeOrder.where((t) => byType.containsKey(t)).toList();

    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assignedColor != null
              ? assignedColor!.withValues(alpha: 0.35)
              : cs.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clientName,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entries.length}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              const SizedBox(width: 3),
              // Convert-to-Folder trigger -- opens the "Create Folder"
              // sheet (saved_documents_section.dart) pre-filled with this
              // column's name and its full document list. The "No
              // Client" column passes an empty suggested name rather
              // than the literal placeholder label, since "No Client"
              // isn't a real folder name anyone would want.
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onConvertToFolder(
                  clientName == _kNoClientLabel ? '' : clientName,
                  entries,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    size: 14,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final type in orderedTypes) ...[
                  _DocKanbanTypeHeader(type: type, count: byType[type]!.length),
                  const SizedBox(height: 4),
                  for (final entry in byType[type]!) _DocKanbanCard(entry: entry),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini sub-section header inside a client column, grouping that client's
// cards by document type -- a scaled-down version of the home screen's
// My Invoices / My Quotes / My Receipts / My Expenses SectionHeader.
// Kept as its own tiny widget rather than reusing SectionHeader directly:
// SectionHeader is sized for a full-width section (label + count +
// sort/layout/display toggles) and none of those controls fit or apply
// inside a 165-wide kanban column -- just a label and a count.
class _DocKanbanTypeHeader extends StatelessWidget {
  final String type;
  final int count;
  const _DocKanbanTypeHeader({required this.type, required this.count});

  static const Map<String, Color> _typeColors = {
    'Invoice': Color(0xFF1565C0),
    'Quote': Color(0xFF7B1FA2),
    'Receipt': Color(0xFF2E7D32),
    'Expense': kExpenseAccent,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _typeColors[type] ?? cs.primary;
    final label = '${type}s';

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}
