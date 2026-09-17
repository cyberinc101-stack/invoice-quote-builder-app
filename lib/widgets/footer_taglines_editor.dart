// footer_taglines_editor.dart
// lib/widgets/footer_taglines_editor.dart
//
// FOOTER TAGLINES PASS (new file): the add/remove/edit UI for a
// template's footer taglines — a row of 3–6 icon+text items shown at
// the bottom of the document (see doc_footer.dart for the render
// side). Shared by all three template sheets (Invoice's
// step_templates.dart, Quote's quote_step_template.dart, Receipt's
// receipt_step_template.dart) instead of copy-pasting the same list
// editor into each.
//
// Enforced range: 0 items (feature simply has nothing to show yet) or
// 3–6 items — there is no 1- or 2-item state. Starting from empty,
// "Add Footer Taglines" adds three blank items at once. From there,
// "+ Add Item" adds one more (disabled at 6), each row's remove button
// is disabled once exactly 3 remain, and "Remove All" clears back to
// empty in one step. This keeps the widget from ever landing in an
// under-the-minimum state without an explicit "start over" action.
//
// Each row is icon (tap to cycle through the curated
// FooterTaglineIcon set via a popup menu) + a single-line text field
// capped at kFooterTaglineMaxChars with its own counter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/footer_tagline.dart';

class FooterTaglinesEditor extends StatefulWidget {
  final List<FooterTaglineItem> initialItems;
  final Color accent;
  final ValueChanged<List<FooterTaglineItem>> onChanged;

  const FooterTaglinesEditor({
    super.key,
    required this.initialItems,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<FooterTaglinesEditor> createState() => _FooterTaglinesEditorState();
}

class _FooterTaglinesEditorState extends State<FooterTaglinesEditor> {
  late List<FooterTaglineItem> _items;
  late List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems.map((i) => i.copyWith()).toList();
    _ctrls = _items.map((i) => TextEditingController(text: i.text)).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(text: _ctrls[i].text);
    }
    widget.onChanged(_items.map((i) => i.copyWith()).toList());
  }

  void _addBlankSet() {
    setState(() {
      for (var i = 0; i < kFooterTaglinesMin; i++) {
        _items.add(FooterTaglineItem());
        _ctrls.add(TextEditingController());
      }
    });
    _emit();
  }

  void _addOne() {
    if (_items.length >= kFooterTaglinesMax) return;
    setState(() {
      _items.add(FooterTaglineItem());
      _ctrls.add(TextEditingController());
    });
    _emit();
  }

  void _removeAt(int index) {
    if (_items.length <= kFooterTaglinesMin) return;
    setState(() {
      _items.removeAt(index);
      _ctrls.removeAt(index).dispose();
    });
    _emit();
  }

  void _removeAll() {
    setState(() {
      for (final c in _ctrls) {
        c.dispose();
      }
      _items = [];
      _ctrls = [];
    });
    _emit();
  }

  void _setIcon(int index, FooterTaglineIcon icon) {
    setState(() => _items[index] = _items[index].copyWith(icon: icon));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;

    if (_items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show a row of social/contact links at the bottom of the document (e.g. Instagram — @yourbusiness). 3–6 items, evenly spaced.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _addBlankSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 18),
                  const SizedBox(width: 6),
                  Text('Add Footer Taglines',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_items.length}/$kFooterTaglinesMax items',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5))),
            GestureDetector(
              onTap: _removeAll,
              child: Text('Remove All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PopupMenuButton<FooterTaglineIcon>(
                  tooltip: 'Choose icon',
                  onSelected: (icon) => _setIcon(i, icon),
                  itemBuilder: (_) => FooterTaglineIcon.values
                      .map((icon) => PopupMenuItem(
                            value: icon,
                            child: Row(
                              children: [
                                Icon(icon.icon, size: 16, color: accent),
                                const SizedBox(width: 8),
                                Text(icon.label, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(_items[i].icon.icon, size: 18, color: accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrls[i],
                    maxLength: kFooterTaglineMaxChars,
                    inputFormatters: [LengthLimitingTextInputFormatter(kFooterTaglineMaxChars)],
                    onChanged: (_) => _emit(),
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'e.g. @yourbusiness',
                      hintStyle: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.35)),
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accent, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close_rounded, size: 18,
                        color: _items.length <= kFooterTaglinesMin
                            ? colorScheme.onSurface.withValues(alpha: 0.2)
                            : Colors.redAccent),
                    onPressed: _items.length <= kFooterTaglinesMin ? null : () => _removeAt(i),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_items.length < kFooterTaglinesMax)
          GestureDetector(
            onTap: _addOne,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Text('Add Item', style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ),
        if (_items.length <= kFooterTaglinesMin) ...[
          const SizedBox(height: 6),
          Text('Minimum $kFooterTaglinesMin items — remove one at a time is disabled below this.',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ],
    );
  }
}
