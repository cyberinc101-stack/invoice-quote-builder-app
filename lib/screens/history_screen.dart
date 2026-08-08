import 'package:flutter/material.dart';
import '../widgets/very_top_header.dart';
import '../widgets/saved_documents_containers.dart';
import 'settings_screen.dart';
import '../helpers/lang_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DocSortOption _sortOption = DocSortOption.mostRecent;

  String _sortLabel(Map<String, String> t) {
    switch (_sortOption) {
      case DocSortOption.mostRecent:
        return t['history_sort_most_recent']!;
      case DocSortOption.alphabetical:
        return t['history_sort_alphabetical']!;
      case DocSortOption.lastEdited:
        return t['history_sort_last_edited']!;
      case DocSortOption.byType:
        return 'By Type';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = watchLang(context);

    return Scaffold(
      appBar: VeryTopHeader(
        showBackButton: true,
        onHomeTap: () => Navigator.pop(context),
        onPremiumTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t['history_premium_soon']!)),
          );
        },
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSortBar(context, t),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SavedDocumentsContainers(sortOption: _sortOption),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(BuildContext context, Map<String, String> t) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDefault = _sortOption == DocSortOption.mostRecent;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _showSortSheet(context, t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDefault
                    ? colorScheme.surface
                    : (isDark
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.07)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDefault
                      ? (isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : const Color(0xFFE8E8E8))
                      : (isDark
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : const Color(0xFF1A1A2E).withValues(alpha: 0.25)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: isDefault
                        ? colorScheme.onSurface
                        : (isDark
                            ? colorScheme.primary
                            : const Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _sortLabel(t),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDefault
                          ? colorScheme.onSurface
                          : (isDark
                              ? colorScheme.primary
                              : const Color(0xFF1A1A2E)),
                    ),
                  ),
                  if (!isDefault) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _sortOption = DocSortOption.mostRecent),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: isDark
                            ? colorScheme.primary
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, Map<String, String> t) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t['history_sort_sheet_title']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SortTile(
                icon: Icons.access_time_rounded,
                label: t['history_sort_most_recent']!,
                isSelected: _sortOption == DocSortOption.mostRecent,
                onTap: () {
                  setState(() => _sortOption = DocSortOption.mostRecent);
                  Navigator.pop(context);
                },
              ),
              _SortTile(
                icon: Icons.sort_by_alpha_rounded,
                label: t['history_sort_alphabetical_full']!,
                isSelected: _sortOption == DocSortOption.alphabetical,
                onTap: () {
                  setState(() => _sortOption = DocSortOption.alphabetical);
                  Navigator.pop(context);
                },
              ),
              _SortTile(
                icon: Icons.edit_rounded,
                label: t['history_sort_last_edited']!,
                isSelected: _sortOption == DocSortOption.lastEdited,
                onTap: () {
                  setState(() => _sortOption = DocSortOption.lastEdited);
                  Navigator.pop(context);
                },
              ),
              _SortTile(
                icon: Icons.style_rounded,
                label: 'By Type',
                isSelected: _sortOption == DocSortOption.byType,
                onTap: () {
                  setState(() => _sortOption = DocSortOption.byType);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _SortTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? colorScheme.primary : const Color(0xFF1A1A2E);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : (isDark
                  ? colorScheme.surfaceContainerHighest
                  : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? activeColor : colorScheme.onSurface,
          size: 18,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? activeColor : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, size: 18, color: activeColor)
          : Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
    );
  }
}
