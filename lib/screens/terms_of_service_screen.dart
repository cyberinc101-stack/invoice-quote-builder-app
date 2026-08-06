import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  static const String _lastUpdated = 'August 6, 2026';
  static const String _appName = 'Invoice & Quote Generator Pro';
  static const String _companyName = 'CyberInc';
  static const String _contactEmail = 'cyberinc101@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card — always dark gradient, looks great in both modes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1A2E).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '$_appName Terms of Service',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Last updated: $_lastUpdated',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _section(context, '1. Agreement to Terms',
              Icons.handshake_outlined,
              'By downloading, installing, or using the $_appName application ("App"), provided by $_companyName ("we," "us," or "our"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.',
            ),
            _section(context, '2. Use of the App',
              Icons.phone_android_rounded,
              'You agree to use the App only for lawful purposes and in a manner that does not infringe the rights of others. You must not:\n\n'
              '• Use the App for any unlawful or fraudulent purpose, including generating fraudulent invoices, quotes, or receipts.\n'
              '• Reproduce, duplicate, copy, or resell any part of the App in violation of these Terms.\n'
              '• Attempt to gain unauthorised access to any part or feature of the App.\n'
              '• Transmit any unsolicited or unauthorised advertising or promotional material.\n'
              '• Engage in any conduct that restricts or inhibits anyone\'s use or enjoyment of the App.',
            ),
            _section(context, '3. Intellectual Property',
              Icons.copyright_rounded,
              'The App and its entire contents, features, and functionality — including but not limited to all information, software, text, displays, document templates, images, and design — are owned by $_companyName and are protected by applicable intellectual property laws.\n\n'
              'You are granted a limited, non-exclusive, non-transferable, revocable licence to use the App for your personal or business invoicing purposes.',
            ),
            _section(context, '4. User Content',
              Icons.edit_document,
              'You retain all rights to the content you create using the App, including your business profile, client details, and the invoices, quotes, and receipts you generate ("User Content"). By using the App, you grant us a limited licence to process your User Content solely for the purpose of operating and providing the App\'s services to you — for example, rendering document previews and generating PDF exports.\n\n'
              'You are solely responsible for your User Content, including the accuracy of financial figures and the accounts you bill, and warrant that it does not violate any third-party rights or applicable laws.',
            ),
            _section(context, '5. In-App Purchases & Subscriptions',
              Icons.payment_rounded,
              'The App may offer premium features via in-app purchases or subscriptions, such as additional document templates or export options. All purchases are processed through the Google Play Store or Apple App Store. Prices are subject to change with notice. Refunds are handled in accordance with the respective store\'s refund policies.\n\n'
              'Subscriptions will automatically renew unless cancelled at least 24 hours before the end of the current period.',
            ),
            _section(context, '6. Disclaimer of Warranties',
              Icons.warning_amber_rounded,
              'THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.\n\n'
              'We do not warrant that the App will be uninterrupted, error-free, or free of viruses or other harmful components, and we make no warranty regarding the accuracy of any tax, currency, or financial calculations performed by the App. You are responsible for verifying all figures before sending a document to a client or relying on it for accounting or tax purposes.',
            ),
            _section(context, '7. Limitation of Liability',
              Icons.gavel_rounded,
              'TO THE FULLEST EXTENT PERMITTED BY LAW, $_companyName SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE APP, INCLUDING ANY LOSSES ARISING FROM INACCURATE OR LOST INVOICE, QUOTE, OR RECEIPT DATA.\n\n'
              'OUR TOTAL LIABILITY TO YOU FOR ANY CLAIMS ARISING FROM THESE TERMS OR YOUR USE OF THE APP SHALL NOT EXCEED THE AMOUNT YOU PAID US IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM.',
            ),
            _section(context, '8. Privacy',
              Icons.privacy_tip_outlined,
              'Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference. Please review our Privacy Policy to understand our practices.',
            ),
            _section(context, '9. Termination',
              Icons.block_rounded,
              'We may terminate or suspend your access to the App immediately, without prior notice or liability, if you breach these Terms. Upon termination, your right to use the App will immediately cease. You may also stop using the App at any time by uninstalling it from your device.',
            ),
            _section(context, '10. Governing Law',
              Icons.account_balance_rounded,
              'These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles. Any disputes arising from these Terms or your use of the App shall be resolved through binding arbitration or in the courts of competent jurisdiction.',
            ),
            _section(context, '11. Changes to Terms',
              Icons.update_rounded,
              'We reserve the right to modify these Terms at any time. We will notify you of any changes by updating the "Last updated" date. Your continued use of the App after such changes constitutes acceptance of the revised Terms.',
            ),
            _section(context, '12. Contact Us',
              Icons.mail_outline_rounded,
              '',
              contactCard: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    String body, {
    bool contactCard = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            if (contactCard) ...[
              // Contact card — always uses dark gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1A2E).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _companyName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Software Development',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.mail_outline_rounded,
                              color: Colors.white70, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          _contactEmail,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              Text(
                body,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.65,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
