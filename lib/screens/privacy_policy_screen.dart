import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  static const String _lastUpdated = 'August 6, 2026';
  static const String _appName = 'Invoice & Quote Generator Pro';
  static const String _companyName = 'CyberInc';
  static const String _contactEmail = 'cyberinc101@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            // Header card — always dark gradient
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
                    child: const Icon(Icons.privacy_tip_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '$_appName Privacy Policy',
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

            _section(context, '1. Introduction',
              Icons.info_outline_rounded,
              '$_companyName ("we," "our," or "us") operates the $_appName mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App to create invoices, quotes, and receipts. Please read this policy carefully. If you disagree with its terms, please discontinue use of the App immediately.',
            ),
            _section(context, '2. Information We Collect',
              Icons.folder_open_rounded,
              'We may collect information about you in a variety of ways. The information we may collect via the App includes:\n\n'
              '• Business Profile Data: Your business name, logo, address, email, phone number, and payment or banking details that you enter to appear on the invoices, quotes, and receipts you create.\n\n'
              '• Client Data: Names, email addresses, phone numbers, and billing addresses of your clients or customers, entered by you for the purpose of generating documents.\n\n'
              '• Document Content: Line items, descriptions, pricing, tax rates, discounts, notes, and payment terms you enter into invoices, quotes, and receipts.\n\n'
              '• Device Data: Information about your mobile device, including device ID, operating system, and IP address, collected automatically when you access the App.\n\n'
              '• Usage Data: Information about how you use the App, such as which features you access and how often, collected through analytics tools where enabled.',
            ),
            _section(context, '3. How We Use Your Information',
              Icons.settings_outlined,
              'Having accurate information about you permits us to provide you with a smooth, efficient, and customised experience. Specifically, we may use information collected about you to:\n\n'
              '• Generate and store your invoices, quotes, and receipts on your device.\n'
              '• Populate document previews and exported PDFs with your business and client details.\n'
              '• Send you in-app alerts and reminders, such as notices about overdue invoices or expiring quotes.\n'
              '• Send you administrative information, such as updates or changes to our terms.\n'
              '• Respond to customer service requests and support needs.\n'
              '• Monitor and analyse usage to improve the App.\n'
              '• Prevent fraudulent transactions and monitor against misuse.',
            ),
            _section(context, '4. Data Storage',
              Icons.storage_rounded,
              'Your business profile, client details, and documents are stored locally on your device. We do not transmit this data to our servers unless you explicitly choose to share or export a document (for example, emailing a PDF invoice to a client). You are responsible for maintaining the security of your device and any backup copies of your data.',
            ),
            _section(context, '5. Disclosure of Your Information',
              Icons.share_outlined,
              'We do not sell, trade, or otherwise transfer your personally identifiable information to third parties. We may share information with:\n\n'
              '• Service Providers: Third-party vendors who assist us in operating the App, such as subscription billing processors, provided that those parties agree to keep this information confidential.\n\n'
              '• Legal Requirements: If required by law or in response to valid requests by public authorities, we may disclose your information.',
            ),
            _section(context, '6. Third-Party Services',
              Icons.link_rounded,
              'The App may use third-party services to operate certain features, including subscription and payment processing through the Google Play Store or Apple App Store, and analytics providers. These third parties have their own privacy policies, and we do not accept any responsibility or liability for their policies or processing of your personal information.',
            ),
            _section(context, '7. Children\'s Privacy',
              Icons.child_care_rounded,
              'The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If we learn we have collected personal information from a child under 13 without parental consent, we will delete that information.',
            ),
            _section(context, '8. Security of Your Information',
              Icons.lock_outline_rounded,
              'We use administrative, technical, and physical security measures to help protect your personal, business, and client information. While we have taken reasonable steps to secure the information you provide to us, please be aware that no security measures are perfect or impenetrable.',
            ),
            _section(context, '9. Your Data Rights',
              Icons.verified_user_outlined,
              'Depending on your location, you may have the following rights regarding your personal information:\n\n'
              '• The right to access — you can request a copy of the data we hold about you.\n'
              '• The right to correction — you can request that we correct any inaccurate data.\n'
              '• The right to deletion — you can request that we delete your personal data.\n'
              '• The right to withdraw consent — where processing is based on consent, you may withdraw it at any time.\n\n'
              'Because your business, client, and document data lives locally on your device, you can also delete it directly within the App at any time. To exercise your other rights, please contact us at $_contactEmail.',
            ),
            _section(context, '10. Changes to This Policy',
              Icons.update_rounded,
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date at the top of this policy. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _section(context, '11. Contact Us',
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
