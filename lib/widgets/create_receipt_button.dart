// create_receipt_button.dart
// lib/widgets/create_receipt_button.dart
//
// UPDATED: now pushes ReceiptTemplateChooserScreen ("Choose a Design")
// first, matching how the invoice and quote "Create" buttons work — the
// chooser is responsible for pushing CreateReceiptScreen(layoutTemplateId:)
// once a design is picked, so this button no longer navigates to
// CreateReceiptScreen directly.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../create_receipt/receipt_template_chooser_screen.dart';

class CreateReceiptButton extends StatelessWidget {
  const CreateReceiptButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ReceiptProvider>().resetReceiptData();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReceiptTemplateChooserScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0x6043A047),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_rounded, color: Colors.white, size: 22),
            SizedBox(height: 6),
            Text(
              'Create Receipt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
