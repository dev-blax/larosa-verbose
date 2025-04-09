import 'package:flutter/material.dart';

import 'business_register.dart';
import 'personal_register.dart';

class EulaScreen extends StatelessWidget {
  final bool isBusiness;
  const EulaScreen({Key? key, required this.isBusiness}) : super(key: key);

  static const String eulaText = '''
Explore LaRosa – Terms of Use (EULA)

Effective Date: January 25, 2025

Welcome to Explore LaRosa (“the App”), operated by Explore LaRosa. By downloading, installing, or using the App, you agree to be bound by these Terms of Use (“Terms” or “EULA”). If you do not agree, you must not access or use the App.

1. Acceptance of These Terms
- By creating an account, logging in, or otherwise using the App, you confirm that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.
- You must be at least 18 years old (or the age of majority in your jurisdiction) to use this App.

2. Minimal Data Collection
- We collect only your name, phone number, and email address at registration to create and maintain your user account.
- We do not collect or store any other personal data beyond these three items.
- We do not engage in cross-app tracking or targeted advertising, and we do not sell your information to third parties.

3. User-Generated Content
- Users may upload or post photos, videos, comments, or other materials (“User Content”).
- We strictly prohibit any content that is hateful, harassing, pornographic, violent, or otherwise objectionable.
- We reserve the right to remove such content immediately and ban or eject the offending user.
- Reported content is reviewed within 24 hours. Please use the in-app “Report” feature if you encounter violations.
- Users can block abusive users, and once blocked, that user’s content will no longer be visible to you.

4. Your Responsibilities
- Keep your account credentials confidential.
- Provide accurate registration details (name, phone number, email) and update them if they change.
- Do not post content that violates these Terms or any applicable laws.

5. Data Sharing & Usage
- Aside from storing your name, phone number, and email address for account management, we do not collect additional personal data.
- We do not use any collected data for targeted advertising or cross-app tracking.
- We may share data with legal authorities if required by law, but we do not share it with advertisers or data brokers.

6. Intellectual Property
- All non-user content is the property of Explore LaRosa or its licensors.
- You grant us a license to use your submitted content to operate the App.

7. Termination and Account Ejection
- We reserve the right to suspend or terminate your account if you breach these Terms.
- Offending content may be removed and the user banned without prior notice.

8. Liability and Disclaimer
- The App is provided “as is” without warranties of any kind.
- We are not liable for any damages arising from your use of the App.

9. Changes to These Terms
- We may update these Terms from time to time. Continued use of the App constitutes acceptance of any revised Terms.

10. Governing Law
- These Terms are governed by the laws of your jurisdiction.

11. Contact Us
- For questions or concerns, please contact us at explorelarosa@gmail.com or +255 763 084 848.

By tapping “Accept” or using the App, you agree to these Terms of Use.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen design matching the AccountType page style.
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/lady-nice-hair.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Header title
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              'Terms of Use',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  )
                ],
              ),
            ),
          ),
          // Scrollable EULA text container
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    eulaText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Accept / Decline buttons at the bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // On decline, navigate back to the previous screen.
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // On accept, navigate to the appropriate registration page.
                    // Replace BusinessRegisterScreen and RegisterScreen with your actual pages.
                    if (isBusiness) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusinessRegisterScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalRegisterScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    elevation: 0,
                    backgroundColor: const Color(0xff34a4f9),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
