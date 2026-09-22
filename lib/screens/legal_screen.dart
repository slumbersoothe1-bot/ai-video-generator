import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

const String kSupportEmail = 'slumbersoothe1@gmail.com';

enum LegalPage { privacy, terms, contact }

extension LegalPageInfo on LegalPage {
  String get title {
    switch (this) {
      case LegalPage.privacy:
        return 'Privacy Policy';
      case LegalPage.terms:
        return 'Terms & Conditions';
      case LegalPage.contact:
        return 'Contact Us';
    }
  }

  IconData get icon {
    switch (this) {
      case LegalPage.privacy:
        return Icons.privacy_tip_outlined;
      case LegalPage.terms:
        return Icons.gavel_outlined;
      case LegalPage.contact:
        return Icons.support_agent_outlined;
    }
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(page.title, style: AppText.heading.copyWith(fontSize: 20))),
                    Icon(page.icon, color: AppColors.accent),
                  ],
                ),
              ),
              _LegalNavigation(current: page),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(page.title, style: AppText.display.copyWith(fontSize: 28)),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Last updated: September 22, 2026', style: AppText.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.lg),
                      ..._sections(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    if (page == LegalPage.contact) return _contactSections(context);
    final sections = page == LegalPage.privacy ? _privacySections : _termsSections;
    return sections.map((section) => _LegalSectionView(section: section)).toList();
  }

  List<Widget> _contactSections(BuildContext context) {
    return [
      const _LegalSectionView(section: _LegalSection(
        title: 'Support',
        body: 'For account, billing, privacy, safety, or technical questions, contact our support team at the address below. Please do not include passwords, authentication codes, API keys, or other secrets in your message.',
      )),
      SurfaceCard(
        glow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Official support email', style: AppText.label),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(kSupportEmail, style: AppText.heading.copyWith(color: AppColors.accent)),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: kSupportEmail));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support email copied.')));
                }
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy email address'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const _LegalSectionView(section: _LegalSection(
        title: 'What to include',
        body: 'To help us respond, include the email address associated with your account, a clear description of the issue, the affected feature, and relevant dates or error messages. We will only use this information to handle your request and protect the service.',
      )),
      const _LegalSectionView(section: _LegalSection(
        title: 'Legal and privacy requests',
        body: 'Use the same support email for access, correction, deletion, objection, portability, consent withdrawal, or other privacy requests. We may need to verify your identity before completing a request.',
      )),
    ];
  }
}

class _LegalNavigation extends StatelessWidget {
  const _LegalNavigation({required this.current});
  final LegalPage current;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: LegalPage.values.map((page) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              selected: page == current,
              label: Text(page.title),
              avatar: Icon(page.icon, size: 16),
              onSelected: page == current
                  ? null
                  : (_) => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => LegalDocumentScreen(page: page)),
                      ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    void open(LegalPage page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalDocumentScreen(page: page)));
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: 0,
      children: LegalPage.values.map((page) {
        return TextButton.icon(
          onPressed: () => open(page),
          icon: Icon(page.icon, size: 15),
          label: Text(page.title),
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, textStyle: AppText.label.copyWith(fontSize: 11)),
        );
      }).toList(),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;
}

class _LegalSectionView extends StatelessWidget {
  const _LegalSectionView({required this.section});
  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: AppText.heading.copyWith(fontSize: 17)),
            const SizedBox(height: AppSpacing.sm),
            Text(section.body, style: AppText.bodySecondary.copyWith(height: 1.55)),
          ],
        ),
      ),
    );
  }
}

const List<_LegalSection> _privacySections = [
  _LegalSection(title: '1. Who we are', body: 'AI Video Studio is a creative application that helps users generate and manage AI-assisted images and videos. In this policy, “we”, “us”, and “our” refer to the operator of AI Video Studio. For privacy questions, contact ' + kSupportEmail + '.'),
  _LegalSection(title: '2. Information we collect', body: 'We may collect account information such as your name, email address, authentication records, and account preferences. We collect the prompts, template selections, uploaded assets, generated images and videos, captions, and other content you submit or create through the service. We may collect credit, subscription, referral, and transaction status information; payment card details should be handled by the applicable payment processor and are not intended to be stored by the app. We may also receive device, browser, language, IP-derived region, log, diagnostic, and security information needed to operate and protect the service. If you contact support, we collect the information you choose to provide.'),
  _LegalSection(title: '3. How we receive information', body: 'We receive information directly from you, automatically from the device or browser you use, and from service providers that help us authenticate users, process payments, host files, deliver AI inference, prevent abuse, and measure service performance. We do not intentionally purchase sensitive personal information for the service.'),
  _LegalSection(title: '4. How we use information', body: 'We use information to create and secure accounts; authenticate sessions; process prompts and media generation requests; store, display, and deliver your content; manage credits, subscriptions, and referrals; provide support; communicate service notices; monitor performance and reliability; detect fraud, abuse, and security incidents; comply with law; enforce our agreements; and improve the service. Where required, we request consent before using optional cookies, analytics, or personalized advertising.'),
  _LegalSection(title: '5. Legal bases', body: 'Depending on where you live, we process information because it is necessary to provide the service you request, to perform a contract, to comply with legal obligations, for our legitimate interests in security and service improvement, or because you have given consent. You may withdraw consent for consent-based processing at any time; withdrawal does not affect processing that occurred before withdrawal.'),
  _LegalSection(title: '6. Cookies and similar technologies', body: 'We may use strictly necessary cookies or local storage for authentication, security, preferences, session continuity, and core functionality. Optional analytics and advertising technologies may be used only where permitted and, where required, after consent. You can manage cookies through your browser settings and any consent controls we provide. Blocking essential storage may prevent sign-in or other features from working.'),
  _LegalSection(title: '7. Google AdSense and advertising', body: 'If advertising is enabled, Google and its partners may use cookies, device identifiers, or similar technologies to serve, measure, and personalize ads in accordance with their own policies. Where required by applicable law, we will request consent before personalized advertising and provide an available non-personalized advertising option. You can review or change Google advertising personalization settings through Google Ads Settings and review Google’s advertising privacy information at https://policies.google.com/technologies/ads. Advertising partners may process information under their own privacy notices.'),
  _LegalSection(title: '8. When we share information', body: 'We may share information with infrastructure, authentication, database, storage, AI inference, analytics, customer support, payment, advertising, security, and professional service providers that process it on our instructions or under their own terms where applicable. We may disclose information to comply with law, respond to lawful requests, protect users and the service, investigate fraud or abuse, or support a merger, acquisition, financing, or asset transfer. We do not sell your personal information for money. We do not give third parties permission to use your private prompts or media for their own unrelated marketing.'),
  _LegalSection(title: '9. AI processing and generated content', body: 'To provide generation features, prompts and relevant assets may be sent to configured AI inference providers. Do not submit confidential, regulated, or highly sensitive information unless you have the right to do so and accept the risks of processing. AI output can be inaccurate, biased, incomplete, or similar to output generated for other users; review it before publication or commercial use.'),
  _LegalSection(title: '10. International transfers and retention', body: 'Our providers may process information in countries other than your own. Where required, we use appropriate contractual, technical, or legal safeguards for international transfers. We retain information for as long as needed to provide the service, maintain business and security records, resolve disputes, enforce agreements, or comply with legal obligations. Retention periods depend on the type and sensitivity of the information.'),
  _LegalSection(title: '11. Security', body: 'We use reasonable administrative, technical, and organizational safeguards designed to protect information. No online service, transmission, or storage system is completely secure. You are responsible for using a strong password, protecting your account, and notifying us promptly if you suspect unauthorized access.'),
  _LegalSection(title: '12. Your rights', body: 'Subject to applicable law and verification, you may have the right to access, correct, delete, restrict, or receive a copy of your personal information; object to certain processing; withdraw consent; and lodge a complaint with a data protection authority. To submit a request, contact ' + kSupportEmail + '. We may retain information where legally required or where necessary for legitimate and lawful purposes.'),
  _LegalSection(title: '13. Children', body: 'The service is not directed to children under 13, or the higher minimum age required in the user’s jurisdiction. We do not knowingly collect personal information from children who are below the applicable age. If you believe a child has provided information, contact us so we can review and take appropriate action.'),
  _LegalSection(title: '14. Changes to this policy', body: 'We may update this policy to reflect changes in the service, law, or our practices. We will post the revised version and update the date above. If a change is material, we will provide additional notice where required.'),
];

const List<_LegalSection> _termsSections = [
  _LegalSection(title: '1. Agreement', body: 'These Terms & Conditions govern your access to and use of AI Video Studio. By creating an account, accessing the service, or using any feature, you agree to these Terms and the Privacy Policy. If you do not agree, do not use the service.'),
  _LegalSection(title: '2. Eligibility and accounts', body: 'You must be legally able to enter a binding agreement and meet the minimum age requirements that apply where you live. You must provide accurate information, keep your credentials confidential, and promptly notify us of suspected unauthorized access. You are responsible for activity under your account.'),
  _LegalSection(title: '3. The service and AI features', body: 'The service provides creative tools, templates, AI-assisted generation, storage, captions, and related features. Features may change, be limited, or become unavailable. AI systems do not understand context like a human professional and may produce inaccurate, offensive, or unsuitable results. You must review all output before relying on it, publishing it, or using it commercially.'),
  _LegalSection(title: '4. Your content and permissions', body: 'You retain ownership of content you submit, including prompts, images, video, text, and other materials, subject to the rights needed to operate the service. You grant us a limited, worldwide, non-exclusive license to host, reproduce, process, transmit, and display your content only as needed to provide, secure, maintain, and improve the service, or as otherwise described in the Privacy Policy. You represent that you have all rights, permissions, and consents needed for the content and that it does not violate law or third-party rights.'),
  _LegalSection(title: '5. Acceptable use', body: 'You may not use the service to break the law, infringe intellectual property or privacy rights, impersonate others, create deceptive or abusive content, exploit or endanger children, distribute malware, reverse engineer protected components, bypass limits or access controls, interfere with the service, attempt unauthorized access, or use generated content to facilitate harm. We may remove content or suspend accounts when reasonably necessary to protect users, providers, or the service.'),
  _LegalSection(title: '6. Credits, subscriptions, and payments', body: 'Some features may require credits or a paid plan. Prices, renewal terms, taxes, included usage, and refund rules will be shown at purchase or in the applicable order terms. Credits may be non-transferable and may expire or be restricted as disclosed. You authorize the applicable payment provider to charge valid payment methods. Contact support promptly about billing errors; mandatory consumer rights are not limited.'),
  _LegalSection(title: '7. Intellectual property', body: 'The service, software, branding, templates, design, documentation, and non-user materials are owned by us or our licensors and are protected by applicable law. Except for the limited right to use the service under these Terms, no ownership or license is transferred. You may not copy, resell, scrape, or commercially exploit service components without permission.'),
  _LegalSection(title: '8. Third-party services and advertising', body: 'The service may rely on third-party hosting, AI inference, payments, analytics, app stores, advertising, and links. Third-party services are governed by their own terms and privacy notices. We do not control and are not responsible for third-party availability, content, security, or practices. Advertising does not constitute an endorsement of an advertiser or product.'),
  _LegalSection(title: '9. Disclaimers', body: 'To the maximum extent permitted by law, the service and all AI output are provided on an “as is” and “as available” basis without warranties of uninterrupted availability, accuracy, fitness for a particular purpose, non-infringement, or that output will satisfy your requirements. We do not guarantee ad-network approval, legal compliance for a particular business model, or that generated content is unique, safe, or suitable for publication. You are responsible for review, rights clearance, disclosures, and compliance with the laws and platform rules that apply to your use.'),
  _LegalSection(title: '10. Liability limits', body: 'To the maximum extent permitted by law, we will not be liable for indirect, incidental, special, consequential, exemplary, or punitive damages, lost profits, lost data, business interruption, or loss of goodwill arising from or related to the service. Our aggregate liability for claims relating to the service will not exceed the amount you paid us for the service during the applicable period, or the minimum amount required by law if no payment was made. Nothing in these Terms excludes liability that cannot legally be excluded.'),
  _LegalSection(title: '11. Indemnity', body: 'To the extent permitted by law, you agree to defend, indemnify, and hold harmless us and our affiliates, officers, employees, and providers from claims, losses, liabilities, and expenses arising from your content, your violation of these Terms, your unlawful or harmful use of the service, or your infringement of another party’s rights.'),
  _LegalSection(title: '12. Suspension and termination', body: 'You may stop using the service at any time. We may suspend or terminate access for breach, abuse, non-payment, security risk, legal requirement, or operational reasons. On termination, your right to use the service ends; provisions that by their nature should survive, including ownership, disclaimers, liability limits, indemnity, and dispute terms, will survive.'),
  _LegalSection(title: '13. Governing law and disputes', body: 'Unless mandatory law provides otherwise, disputes will be handled under the laws and courts applicable to the operator’s principal place of business. Before filing a formal claim, the parties should attempt in good faith to resolve the issue by contacting ' + kSupportEmail + '. This clause does not remove any non-waivable consumer or data-protection rights.'),
  _LegalSection(title: '14. Changes and contact', body: 'We may update these Terms by posting a revised version and updating the date above. Continued use after an effective update means you accept the revised Terms to the extent permitted by law. Questions about these Terms should be sent to ' + kSupportEmail + '.'),
];
