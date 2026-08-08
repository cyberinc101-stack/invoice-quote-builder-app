// lib/widgets/category_picker.dart
//
// Usage:
//   final picked = await showCategoryPicker(context, selectedId: currentId);
//   if (picked != null) setState(() => currentId = picked.id);
//
// Reads/writes through CategoryProvider (must be above this widget in the
// widget tree via the app's existing MultiProvider in main.dart).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_category.dart';
import '../providers/category_provider.dart';

Future<DocumentCategory?> showCategoryPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<DocumentCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CategoryPickerSheet(selectedId: selectedId),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  final String? selectedId;
  const _CategoryPickerSheet({this.selectedId});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().all;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              TextButton.icon(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                icon: Icon(_showAddForm ? Icons.close_rounded : Icons.add_rounded, size: 18),
                label: Text(_showAddForm ? 'Cancel' : 'New'),
              ),
            ],
          ),
          if (_showAddForm) ...[
            const SizedBox(height: 8),
            _AddCategoryForm(onCreated: (c) {
              setState(() => _showAddForm = false);
              Navigator.pop(context, c);
            }),
          ] else ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final isSelected = c.id == widget.selectedId;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: isSelected ? 0.22 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.color.withValues(alpha: isSelected ? 0.7 : 0.2), width: isSelected ? 1.6 : 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c.icon, color: c.color, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            c.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.color),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddCategoryForm extends StatefulWidget {
  final ValueChanged<DocumentCategory> onCreated;
  const _AddCategoryForm({required this.onCreated});

  @override
  State<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<_AddCategoryForm> {
  final _nameController = TextEditingController();
  String _iconKey = 'more_horiz';
  int _colorValue = 0xFF2196F3;

  static const List<int> _colorChoices = [
    0xFF2196F3, 0xFF9C27B0, 0xFF4CAF50, 0xFFFF9800,
    0xFFE53935, 0xFF00897B, 0xFF5D4037, 0xFF757575,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Category name',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _colorChoices.map((cv) {
            final selected = cv == _colorValue;
            return GestureDetector(
              onTap: () => setState(() => _colorValue = cv),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Color(cv),
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: colorScheme.onSurface, width: 2) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: kCategoryIconChoices.entries.map((e) {
            final selected = e.key == _iconKey;
            return GestureDetector(
              onTap: () => setState(() => _iconKey = e.key),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Color(_colorValue).withValues(alpha: selected ? 0.25 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: selected ? Border.all(color: Color(_colorValue), width: 1.4) : null,
                ),
                child: Icon(e.value, size: 18, color: Color(_colorValue)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(_colorValue),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              final created = await context.read<CategoryProvider>().addCategory(
                    name: name,
                    colorValue: _colorValue,
                    iconKey: _iconKey,
                  );
              widget.onCreated(created);
            },
            child: const Text('Create category', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
