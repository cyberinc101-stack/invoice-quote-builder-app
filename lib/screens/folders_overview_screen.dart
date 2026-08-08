// folders_overview_screen.dart
// lib/screens/folders_overview_screen.dart
//
// Standalone "Folders" browser screen. All the tile-grid/rename/delete
// logic now lives in the shared FoldersGridView widget
// (lib/widgets/folders_grid_view.dart) so it can also be embedded inline
// inside SavedDocumentsSection's "browsing folders" mode. This screen is
// now just that widget wrapped in a Scaffold + AppBar, with onFolderTap
// pushing into SavedDocumentsSection(initialFolder: name) — kept around
// as a standalone entry point (e.g. reachable from Settings or elsewhere
// in nav) alongside the newer inline browsing on the home/documents screen.

import 'package:flutter/material.dart';
import '../widgets/folders_grid_view.dart';
import '../widgets/saved_documents/saved_documents_section.dart';

class FoldersOverviewScreen extends StatelessWidget {
  const FoldersOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: FoldersGridView(
        onFolderTap: (name) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(name)),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SavedDocumentsSection(initialFolder: name),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
